/**
 * Loop mode — keep working until the model is truly done.
 *
 *   /loop on [max]    start looping (default 100 continuations, 0 = infinite)
 *   /loop off         stop looping now
 *   /loop interactive toggle whether the agent may ask the user while looping
 *
 * The loop ends when the model calls `loop_done`: either the task is complete, or
 * every option is exhausted and nothing viable remains.
 *
 * Interactive mode is off by default and stays set until toggled or the session
 * restarts. With it off, the question tool (`ask_user`) is hidden from the
 * model's tool list while the loop runs and the prompt tells it to decide on its
 * own instead of asking.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const TOOL_NAME = "loop_done";
const STATUS_KEY = "10loop";
const DEFAULT_MAX = 100;

/** Command verbs, reused as the argument completions. */
const ACTIONS = ["on", "off", "interactive"];

/** The question tool hands control to a human; blocked while interactive is off. */
const QUESTION_TOOL = "ask_user";

/** Tokens paid per stop attempt. Keep these short. */
const CONTINUE = "Loop active. Do not stop. Take the next concrete step now.";
const ASK = `Call ${TOOL_NAME} when the task is complete; if you need the user's input, ask them.`;
const NO_ASK =
  "Interactive is off: do not ask the user, and ask_user is disabled. Choose the most " +
  "reasonable option, state the assumption, and keep working. If a decision genuinely " +
  `requires the user, call ${TOOL_NAME} and name that decision.`;
const CAP = `Loop iteration cap reached. Wrap up now, then call ${TOOL_NAME} if the task is complete.`;

const description = (ask: boolean) =>
  "Declare that the loop is finished. Call this if either (1) the task is complete and verified, " +
  "or (2) all options are exhausted. " +
  (ask
    ? "If you need user input/approval, ask the question and continue working after."
    : "Do not ask the user: interactive mode is off. If a decision is genuinely theirs, " +
      "name it in the reason.");

export default function (pi: ExtensionAPI) {
  let active = false;
  let iterations = 0;
  let maxIterations = DEFAULT_MAX;
  let capAnnounced = false;
  let interactive = false;

  const progress = () => {
    const count =
      maxIterations > 0
        ? `loop ${iterations}/${maxIterations}`
        : `loop ${iterations}`;
    return `${count} (${interactive ? "" : "no-"}ask)`;
  };

  /** The message that keeps the turn going. */
  const nudge = () => {
    if (capAnnounced) {
      return interactive ? CAP : `${CAP} Interactive is off: do not ask the user.`;
    }
    return `${CONTINUE} ${interactive ? ASK : NO_ASK}`;
  };

  const renderStatus = (ctx: ExtensionContext) =>
    ctx.ui.setStatus(STATUS_KEY, active ? progress() : undefined);

  /** Add or remove loop_done from the model's active tool set. */
  const setToolEnabled = (enabled: boolean) => {
    const current = pi.getActiveTools();
    const next = enabled
      ? [...new Set([...current, TOOL_NAME])]
      : current.filter((name) => name !== TOOL_NAME);
    if (next.length !== current.length) pi.setActiveTools(next);
  };

  /** Tear the loop down, clear the status line, and optionally say why. */
  const stop = (ctx: ExtensionContext, notice?: string) => {
    active = false;
    iterations = 0;
    capAnnounced = false;
    setToolEnabled(false);
    renderStatus(ctx);
    if (notice) ctx.ui.notify(notice, "info");
  };

  const start = (ctx: ExtensionContext, max: number) => {
    active = true;
    iterations = 0;
    capAnnounced = false;
    maxIterations = max;
    setToolEnabled(true);
    renderStatus(ctx);
    ctx.ui.notify(
      `Loop started: ${max > 0 ? `${max} loop(s)` : "infinite"}, ` +
        `${interactive ? "interactive" : "non-interactive"}.`,
      "info",
    );
  };

  // Registered inactive: zero prompt/tool cost until /loop on.
  pi.registerTool({
    name: TOOL_NAME,
    label: "Loop Done",
    description: description(true),
    promptSnippet: "Declare the loop finished when the task is complete",
    promptGuidelines: [
      `Loop mode is active: keep working across turns until you call ${TOOL_NAME}.`,
      `Call ${TOOL_NAME} when you are totally done: the task is complete, or every option is ` +
        "exhausted and no viable path remains. If you stop because you are blocked, name the " +
        "blocker and the approaches you already ruled out in the reason.",
      "Asking the user does not end the loop; continue working after the answer.",
    ],
    defaultActive: false,
    // Active only while looping, so this hook is the loop's own switch: with
    // interactive off, the question tool leaves the declared tool list (and its
    // prompt guidelines) without touching the session's active tool set. The
    // `tool_call` guard below still blocks a direct or nested call by name.
    prepareLoadout: () =>
      active && !interactive
        ? {
            hiddenDeclarations: [QUESTION_TOOL],
            descriptions: { [TOOL_NAME]: description(false) },
          }
        : undefined,
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
      const total = iterations;
      stop(ctx, `Loop stopped by agent after ${total} loop(s).`);
      return {
        content: [
          {
            type: "text",
            text: reason
              ? `Loop ended: ${reason}`
              : "Loop ended. Nothing further to do.",
          },
        ],
        details: { iterations: total, reason },
        terminate: true,
      };
    },
  });

  pi.registerCommand("loop", {
    description: `Keep iterating until the model declares it is done: ${ACTIONS.map(
      (action) => `/loop ${action}`,
    ).join(" | ")}`,
    getArgumentCompletions: (prefix) =>
      ACTIONS.filter((value) => value.startsWith(prefix)).map((value) => ({
        value,
        label: value,
      })),
    handler: async (args, ctx) => {
      const [action, value] = args.trim().split(/\s+/);
      if (action === "on") {
        const parsed = Number.parseInt(value ?? "", 10);
        start(ctx, parsed >= 0 ? parsed : DEFAULT_MAX);
      } else if (action === "off") {
        if (active) {
          stop(ctx, `Loop stopped manually after ${iterations} loop(s).`);
        }
      } else if (action === "interactive") {
        interactive = !interactive;
        renderStatus(ctx);
        ctx.ui.notify(
          `Loop interactivity: ${interactive ? "on" : "off"}.`,
          "info",
        );
      }
    },
  });

  // Interactive off: refuse the question tool. The loadout hook above already
  // hides it; this catches a direct or nested call made by name.
  pi.on("tool_call", (event) => {
    if (!active || interactive) return;
    if (event.toolName !== QUESTION_TOOL) return;
    return {
      block: true,
      reason:
        `${event.toolName} is disabled: interactive mode is off (/loop interactive). ` +
        "Decide yourself, note the assumption, and keep working. " +
        `If the user really must choose, call ${TOOL_NAME} and name the decision.`,
    };
  });

  // Interactive off: restate the rule in the prompt, since the hidden question
  // tool no longer carries it.
  pi.on("before_agent_start", (event) => {
    if (!active || interactive) return;
    event.systemPromptOptions.promptGuidelines.push(
      "Loop mode is running with interactive off: do not ask the user anything and do not wait for approval. " +
        "ask_user is disabled. Pick the most reasonable option, state the " +
        `assumption, and keep working until you call ${TOOL_NAME}.`,
    );
  });

  // The whole loop: fires only when the run would otherwise end.
  pi.on("agent_before_settle", (event, ctx) => {
    if (!active) return;
    // Aborted runs normally skip this boundary; treat a late abort as a stop.
    if (event.outcome === "aborted") return stop(ctx);
    // Note: do NOT gate on event.context.canContinue. It is computed before the
    // entries we return are committed, so it is false whenever the last message is
    // the assistant's — exactly the case we are here to handle. Pi re-checks
    // canContinue itself after committing our custom message.

    // At the cap: announce it once with one last nudge, then stop on the next pass.
    if (maxIterations > 0 && iterations >= maxIterations) {
      if (capAnnounced) return stop(ctx);
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
          content: nudge(),
          display: false,
        },
      ],
      continue: true,
    };
  });

  // Don't leak loop state across /new, /resume, /fork or /reload.
  pi.on("session_start", (_event, ctx) => {
    interactive = false;
    stop(ctx);
  });
}
