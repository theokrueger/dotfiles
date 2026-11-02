/**
 * Loop mode — keep working until the model is truly done.
 *
 *   /loop on [max]   start looping (default 100 continuations, 0 = unlimited)
 *   /loop off        stop looping now
 *   /loop            show status
 *
 * The loop ends when the model calls `loop_done`: either the task is complete, or
 * every option is exhausted and nothing viable remains.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const TOOL_NAME = "loop_done";
const STATUS_KEY = "1loop";
const DEFAULT_MAX = 100;

/** Tokens paid per stop attempt. Keep this short. */
const CONTINUE_TEXT =
  "Loop active. Do not stop. Take the next concrete step now. " +
  `Call ${TOOL_NAME} when the task is complete; ` +
  "if you need the user's input, ask them.";

const CAP_TEXT = `Loop iteration cap reached. Wrap up now, then call ${TOOL_NAME} if the task is complete.`;

export default function (pi: ExtensionAPI) {
  let active = false;
  let iterations = 0;
  let maxIterations = DEFAULT_MAX;
  let capAnnounced = false;

  function progress(): string {
    return maxIterations > 0
      ? `loop ${iterations}/${maxIterations}`
      : `loop ${iterations}`;
  }

  function renderStatus(ctx: ExtensionContext): void {
    ctx.ui.setStatus(STATUS_KEY, active ? progress() : undefined);
  }

  /** Add or remove loop_done from the model's active tool set. */
  function setToolEnabled(enabled: boolean): void {
    const current = pi.getActiveTools();
    const next = enabled
      ? [...new Set([...current, TOOL_NAME])]
      : current.filter((name) => name !== TOOL_NAME);
    if (next.length !== current.length) pi.setActiveTools(next);
  }

  function reset(): void {
    active = false;
    iterations = 0;
    capAnnounced = false;
  }

  /** Tear the loop down, clear the status line, and tell the user why. */
  function stop(ctx: ExtensionContext, notice: string): void {
    active = false;
    setToolEnabled(false);
    renderStatus(ctx);
    ctx.ui.notify(notice, "info");
  }

  function start(ctx: ExtensionContext, max: number): void {
    reset();
    active = true;
    maxIterations = max;
    setToolEnabled(true);
    renderStatus(ctx);
    ctx.ui.notify(
      `Loop on. The agent will keep going until it calls ${TOOL_NAME}.` +
        (max > 0 ? ` Cap: ${max} continuations.` : " No cap."),
      "info",
    );
  }

  // Registered inactive: zero prompt/tool cost until /loop on.
  pi.registerTool({
    name: TOOL_NAME,
    label: "Loop Done",
    description:
      "Declare that the loop is finished. Call this if either (1) the task is complete and verified, " +
      "or (2) all options are exhausted. If you need user input/approval, then ask the question and continue working after",
    promptSnippet: "Declare the loop finished when the task is complete",
    promptGuidelines: [
      `Loop mode is active: keep working across turns until you call ${TOOL_NAME}.`,
      `Call ${TOOL_NAME} when you are totally done: the task is complete, or every option is exhausted and no viable path remains. If you stop because you are blocked, name the blocker and the approaches you already ruled out in the reason.`,
      "Asking the user does not end the loop: use the available question tool for questions, decisions, or approval, then continue working.",
    ],
    defaultActive: false,
    parameters: Type.Object({
      reason: Type.Optional(
        Type.String({
          description:
            "Why you are done: the outcome, or the blocker plus the options you already tried and why none remain.",
        }),
      ),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const reason = params.reason?.trim();
      stop(ctx, `Loop finished after ${iterations} continuation(s).`);
      return {
        content: [
          {
            type: "text",
            text: reason
              ? `Loop ended: ${reason}`
              : "Loop ended. Nothing further to do.",
          },
        ],
        details: { iterations, reason },
        terminate: true,
      };
    },
  });

  pi.registerCommand("loop", {
    description:
      "Keep iterating until the model declares it is done: /loop on [max] | /loop off",
    getArgumentCompletions: (prefix) =>
      ["on", "off", "status"]
        .filter((value) => value.startsWith(prefix))
        .map((value) => ({ value, label: value })),
    handler: async (args, ctx) => {
      const [action, limit] = args.trim().split(/\s+/);
      if (action === "on") {
        const parsed = Number.parseInt(limit ?? "", 10);
        start(ctx, parsed >= 0 ? parsed : DEFAULT_MAX);
      } else if (action === "off") {
        if (active) stop(ctx, "Loop off (requested).");
        else ctx.ui.notify("Loop already off.", "info");
      } else if (action === "" || action === "status") {
        ctx.ui.notify(
          active
            ? `Loop on. ${progress()}. Escape or /loop off to stop.`
            : "Loop off.",
          "info",
        );
      } else {
        ctx.ui.notify("Usage: /loop on [max] | /loop off | /loop", "warning");
      }
    },
  });

  // The whole loop: fires only when the run would otherwise end.
  pi.on("agent_before_settle", async (event, ctx) => {
    if (!active) return;
    // Aborted runs normally skip this boundary; treat a late abort as a stop.
    if (event.outcome === "aborted") {
      stop(ctx, "Loop off (interrupted).");
      return;
    }
    // Note: do NOT gate on event.context.canContinue. It is computed before the
    // entries we return are committed, so it is false whenever the last message is
    // the assistant's — exactly the case we are here to handle. Pi re-checks
    // canContinue itself after committing our custom message.

    // At the cap: announce it once with one last nudge, then stop on the next pass.
    if (maxIterations > 0 && iterations >= maxIterations) {
      if (capAnnounced) {
        stop(ctx, "Loop off (iteration cap reached).");
        return;
      }
      capAnnounced = true;
    }

    iterations += 1;
    renderStatus(ctx);
    return {
      entries: [
        ...event.entries,
        {
          type: "custom_message",
          customType: "loop-continue",
          content: capAnnounced ? CAP_TEXT : CONTINUE_TEXT,
          display: false,
        },
      ],
      continue: true,
    };
  });

  // Don't leak loop state across /new, /resume, /fork or /reload.
  pi.on("session_start", (_event, ctx) => {
    reset();
    setToolEnabled(false);
    renderStatus(ctx);
  });
}
