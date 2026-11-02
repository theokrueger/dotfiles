/**
 * Footer status: rolling average output tokens/sec, e.g. "42.31TPS". In-flight
 * tokens count while streaming; finished responses use real `usage.output` over
 * measured generation time.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

/** Footer statuses sort by key, so the numeric prefix keeps TPS leftmost. */
const STATUS_KEY = "0-tps";
const WINDOW = 5;
const RENDER_INTERVAL_MS = 200;
const MIN_SAMPLE_MS = 150; // shorter samples produce wild rates
const CHARS_PER_TOKEN = 4; // fallback before the provider reports usage

export default function (pi: ExtensionAPI) {
  const samples: { tokens: number; ms: number }[] = [];
  let start: number | undefined;
  let chars = 0;
  let tokens = 0;
  let renderedAt = 0;

  const reset = () => {
    start = undefined;
    chars = 0;
    tokens = 0;
  };

  const sum = (key: "tokens" | "ms") => samples.reduce((a, s) => a + s[key], 0);

  const formatRate = (rate: number) =>
    `${Math.min(rate, 9999).toPrecision(4).padStart(5, "0")}TPS`;

  const IDLE = formatRate(0);

  const render = (ctx: ExtensionContext, now: number, force = false) => {
    if (!force && now - renderedAt < RENDER_INTERVAL_MS) return;
    renderedAt = now;

    const s = start;
    const ms = sum("ms") + (s === undefined ? 0 : now - s);
    const total =
      sum("tokens") +
      (s === undefined ? 0 : Math.max(tokens, chars / CHARS_PER_TOKEN));
    const rate = ms > 0 ? formatRate((total / ms) * 1000) : undefined;
    ctx.ui.setStatus(STATUS_KEY, rate ?? IDLE);
  };

  pi.on("session_start", (_event, ctx) => {
    samples.length = 0;
    renderedAt = 0;
    reset();
    ctx.ui.setStatus(STATUS_KEY, IDLE);
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
        const ms = start === undefined ? 0 : now - start;
        if (e.message.usage.output > 0 && ms >= MIN_SAMPLE_MS) {
          samples.push({ tokens: e.message.usage.output, ms });
          if (samples.length > WINDOW) samples.shift();
        }
        reset();
        render(ctx, now, true);
        break;
      }
      case "text_delta":
      case "thinking_delta":
      case "toolcall_delta":
        start ??= now;
        chars += e.delta.length;
        tokens = Math.max(tokens, e.partial.usage.output);
        render(ctx, now);
        break;
    }
  });
}
