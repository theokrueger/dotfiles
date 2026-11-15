/**
 * Footer status: aggregated output tokens/sec over a rolling 5-second window,
 * e.g. "42.31TPS".
 *
 * The active session's streaming deltas feed the window directly. Other
 * extensions (subagents, asides, ...) contribute through the shared event bus:
 *
 *   pi.events.emit("tps:tokens", { tokens: 12, source: "subagent:scout" });
 *   pi.events.emit("tps:tokens", { cumulative: 812, source: "subagent:scout" });
 *
 * `tokens` is a delta since that source's previous emit; a negative delta
 * corrects an earlier overestimate (the display never drops below zero).
 * `cumulative` is the source's running total, diffed here per stable `source`
 * so emitters stay stateless; a total that drops counts as a restarted source.
 * The whole session shares one aggregate, so emit small, frequent updates for
 * a smooth display.
 *
 * Each token event lands on a timestamped list. Every display prunes entries
 * older than the window and divides by the span they cover (capped at 5s), so
 * a fresh response shows its real rate. Once activity stops, a 1s fade tick
 * ages every entry out of the window, bringing the footer back to zero.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

/** Footer statuses sort by key, so the numeric prefix keeps TPS leftmost. */
const STATUS_KEY = "00-tps";
/** Shared-bus channel other extensions emit token updates on. */
const CONTRIBUTION_EVENT = "tps:tokens";
const WINDOW_MS = 5000; // rolling average window
const RENDER_INTERVAL_MS = 333; // display cadence while tokens arrive
const IDLE_TICK_MS = 1000; // fade cadence once tokens stop
const MIN_SPAN_MS = 150; // shorter spans produce wild rates
const CHARS_PER_TOKEN = 4; // fallback before the provider reports usage

export default function (pi: ExtensionAPI) {
  /** Token counts that arrived within the window, oldest first. */
  const events: { at: number; tokens: number }[] = [];
  /** Last cumulative total reported per external source. */
  const cumulativeBySource = new Map<string, number>();
  let chars = 0; // characters streamed for the current message
  let reported = 0; // largest `usage.output` seen for the current message
  let recorded = 0; // tokens already pushed for the current message
  let renderedAt = 0;
  let currentCtx: ExtensionContext | undefined;
  let idleTimer: ReturnType<typeof setInterval> | undefined;

  const reset = () => {
    chars = 0;
    reported = 0;
    recorded = 0;
  };

  /** Record tokens produced since the last call (0 while nothing is new). */
  const record = (now: number) => {
    const current = Math.max(reported, chars / CHARS_PER_TOKEN);
    if (current > recorded) {
      events.push({ at: now, tokens: current - recorded });
      recorded = current;
    }
  };

  // Keep the numeric field a constant five characters wide so the status row
  // doesn't jump in width while the rate fades to zero.
  const formatRate = (rate: number) => {
    const n = Math.min(Math.max(rate, 0), 9999);
    let value: string;
    if (n >= 1000) value = n.toFixed(0);
    else if (n >= 100) value = Math.min(n, 999.9).toFixed(1);
    else if (n >= 10) value = Math.min(n, 99.99).toFixed(2);
    else value = Math.min(n, 9.99).toFixed(2);
    return `${value.padStart(5, "0")}TPS`;
  };

  const IDLE = formatRate(0);

  /** Drop entries that have aged out of the rolling window. */
  const prune = (now: number) => {
    let cut = 0;
    while (cut < events.length && now - events[cut].at >= WINDOW_MS) cut++;
    if (cut > 0) events.splice(0, cut);
  };

  const render = (ctx: ExtensionContext, now: number, force = false) => {
    prune(now);
    if (!force && now - renderedAt < RENDER_INTERVAL_MS) return;
    renderedAt = now;
    if (!ctx.hasUI) return;

    const total = events.reduce((sum, e) => sum + e.tokens, 0);
    // Divide by the span the window actually covers so a fresh response shows
    // its real rate instead of being diluted by idle time before it started.
    const span = events.length > 0 ? Math.max(MIN_SPAN_MS, now - events[0].at) : WINDOW_MS;
    const rate = (Math.max(0, total) / span) * 1000;
    try {
      ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg("dim", formatRate(rate)));
    } catch {
      // Session replaced mid-flight: there is no footer left to update.
    }
  };

  const stopIdleTimer = () => {
    if (idleTimer !== undefined) {
      clearInterval(idleTimer);
      idleTimer = undefined;
    }
  };

  /** Keep one fade tick alive while the window holds entries. */
  const ensureIdleTimer = (ctx: ExtensionContext) => {
    if (idleTimer !== undefined || !ctx.hasUI || events.length === 0) return;
    idleTimer = setInterval(() => {
      render(ctx, Date.now(), true);
      if (events.length === 0) stopIdleTimer();
    }, IDLE_TICK_MS);
  };

  /**
   * Turn an external update into a non-zero token delta. Supports a delta
   * (`tokens`) or a per-source running total (`cumulative`); malformed input is
   * ignored so a misbehaving extension cannot corrupt the aggregate.
   */
  const contributionTokens = (data: unknown): number | undefined => {
    if (typeof data !== "object" || data === null) return undefined;
    const update = data as {
      tokens?: unknown;
      cumulative?: unknown;
      source?: unknown;
    };

    if (typeof update.tokens === "number" && Number.isFinite(update.tokens)) {
      return update.tokens !== 0 ? update.tokens : undefined;
    }

    if (
      typeof update.cumulative === "number" &&
      Number.isFinite(update.cumulative)
    ) {
      const source =
        typeof update.source === "string" && update.source !== ""
          ? update.source
          : "anonymous";
      const cumulative = Math.max(0, update.cumulative);
      const previous = cumulativeBySource.get(source) ?? 0;
      cumulativeBySource.set(source, cumulative);
      // A total that went backwards means the source restarted; count it fresh.
      const delta = cumulative >= previous ? cumulative - previous : cumulative;
      return delta > 0 ? delta : undefined;
    }

    return undefined;
  };

  pi.events.on(CONTRIBUTION_EVENT, (data) => {
    const ctx = currentCtx;
    if (!ctx) return;
    const tokens = contributionTokens(data);
    if (tokens === undefined) return;
    const now = Date.now();
    events.push({ at: now, tokens });
    ensureIdleTimer(ctx);
    render(ctx, now);
  });

  pi.on("session_start", (_event, ctx) => {
    stopIdleTimer();
    currentCtx = ctx;
    events.length = 0;
    cumulativeBySource.clear();
    renderedAt = 0;
    reset();
    if (ctx.hasUI) ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg("dim", IDLE));
  });

  pi.on("session_shutdown", () => {
    stopIdleTimer();
    currentCtx = undefined;
  });

  pi.on("message_update", (event, ctx) => {
    const e = event.assistantMessageEvent;
    const now = Date.now();

    switch (e.type) {
      case "start":
        reset();
        break;
      case "error":
        reset();
        render(ctx, now, true);
        break;
      case "done": {
        // Swap the char-based streaming estimate for the provider's real count.
        // A negative entry corrects an overestimate; the display clamps at zero.
        if (e.message.usage.output > 0) {
          const delta = e.message.usage.output - recorded;
          if (delta !== 0) events.push({ at: now, tokens: delta });
        }
        reset();
        ensureIdleTimer(ctx);
        render(ctx, now, true);
        break;
      }
      case "text_delta":
      case "thinking_delta":
      case "toolcall_delta":
        chars += e.delta.length;
        reported = Math.max(reported, e.partial.usage.output);
        record(now);
        ensureIdleTimer(ctx);
        render(ctx, now);
        break;
    }
  });
}
