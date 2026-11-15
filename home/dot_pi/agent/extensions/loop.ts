/**
 * Loop mode — keep working until the model is truly done, or a goal is met.
 *
 *   /loop [goal]      loop until the goal is met or the 25-loop cap hits
 *   /loop             current state
 *   /loop off         stop now
 *   /loop interactive toggle whether the agent may ask the user while looping
 *
 * A loop always runs toward a goal. `loop_done` is only a submission: after every
 * turn a fresh judge call (same model, no tools, transcript only) returns met /
 * not_yet / impossible, and "not yet" continues with its reason as the next
 * instruction. Completion rests on what the transcript proves, and the goal starts
 * a turn by itself like Claude Code's /goal:
 *
 *   /loop all tests in test/auth pass and `npm test -- test/auth` exits 0
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import type { AgentMessage, Message } from "@earendil-works/pi-ai";
import { Type } from "typebox";

const TOOL_NAME = "loop_done";
const STATUS_KEY = "20loop";
const ACTIONS = ["off", "interactive"];
const QUESTION_TOOL = "ask_user";

// A task that needs more than this is not a task the loop can finish.
const LOOP_CAP = 25;
const GOAL_LIMIT = 4000; // a condition, not an essay
const JUDGE_MESSAGES = 40; // recent turns carry the evidence
const JUDGE_MAX_TOKENS = 300;
const IDLE_LIMIT = 3; // text-only turns before the loop admits it is spinning

type Verdict = "met" | "not_yet" | "impossible";
type Judgment = { verdict: Verdict; reason: string };

const clip = (text: string, max: number) =>
  text.length > max ? `${text.slice(0, max - 1)}…` : text;
const oneLine = (text: string, max: number) =>
  clip(text.replace(/\s+/g, " ").trim(), max);

const JUDGE_PROMPT = [
  "You judge whether an autonomous coding agent has met its goal, from the transcript only. You cannot run commands or read files.",
  '"met" needs the check the goal names visible with a passing result; the agent saying it is done is not evidence. "not_yet" covers missing or failing proof. "impossible" is for a condition that cannot hold as written — contradictory requirements, missing access. Difficulty is not impossibility.',
  "Reply with exactly one of met, not_yet, or impossible on the first line, then one sentence naming the missing evidence or the next state to reach.",
].join("\n");

/** First line is the verdict, the rest is the reason the agent acts on. */
const parseVerdict = (text: string): Judgment => {
  const [head = "", ...rest] = text.trim().split(/\n+/);
  // Underscore padding makes "met" become "_met_", so "unmet" cannot match.
  const flat = `_${head.toLowerCase().replace(/[^a-z]+/g, "_")}_`;
  const reason = oneLine(rest.join(" ") || head, 200);
  if (flat.includes("impossible")) return { verdict: "impossible", reason };
  if (flat.includes("not_yet") || flat.includes("not_met"))
    return { verdict: "not_yet", reason };
  return { verdict: flat.includes("_met_") ? "met" : "not_yet", reason };
};

/** The last turn's assistant message, or undefined before the first one. */
const lastAssistant = (messages: readonly AgentMessage[]) =>
  messages.findLast((message) => message.role === "assistant");

export default function (pi: ExtensionAPI) {
  let active = false;
  let iterations = 0;
  let interactive = false;
  let goal = ""; // the completion condition while looping
  let lastJudgment: Judgment | undefined;
  let idleTurns = 0;
  let claimed = false; // loop_done called; with a goal, the judge still decides

  const progress = () => {
    const tags = [goal ? "goal" : "", `${interactive ? "" : "no-"}ask`];
    return `loop ${iterations}/${LOOP_CAP} (${tags.filter(Boolean).join(",")})`;
  };

  const renderStatus = (ctx: ExtensionContext) =>
    ctx.ui.setStatus(STATUS_KEY, active ? progress() : undefined);

  const setToolEnabled = (enabled: boolean) => {
    const current = pi.getActiveTools();
    const next = enabled
      ? [...new Set([...current, TOOL_NAME])]
      : current.filter((name) => name !== TOOL_NAME);
    if (next.length !== current.length) pi.setActiveTools(next);
  };

  /** Tear the loop down, clear the status line, and optionally say why. */
  const reset = () => {
    iterations = 0;
    lastJudgment = undefined;
    idleTurns = 0;
    claimed = false;
  };

  const stop = (ctx: ExtensionContext, notice?: string) => {
    active = false;
    goal = "";
    reset();
    setToolEnabled(false);
    renderStatus(ctx);
    if (notice) ctx.ui.notify(notice, "info");
  };

  const start = (ctx: ExtensionContext, goalText: string) => {
    active = true;
    goal = goalText;
    reset();
    setToolEnabled(true);
    renderStatus(ctx);
    const tone = interactive ? "interactive" : "non-interactive";
    const goalPart = `, goal: ${oneLine(goal, 80)}`;
    ctx.ui.notify(
      `Loop started (max ${LOOP_CAP} loops), ${tone}${goalPart}.`,
      "info",
    );
  };

  /** One judge call: the goal, the recent transcript, a verdict. */
  const judge = async (
    ctx: ExtensionContext,
    messages: readonly Message[],
  ): Promise<Judgment | undefined> => {
    if (!ctx.model) return undefined;
    try {
      const reply = await ctx.modelRegistry.complete(
        ctx.model,
        {
          systemPrompt: JUDGE_PROMPT,
          messages: [
            ...messages
              .slice(-JUDGE_MESSAGES)
              .filter((m) => m.role !== "system"),
            {
              role: "user",
              content: `GOAL (definition of done):\n${goal}\n\nReturn the verdict.`,
              timestamp: Date.now(),
            },
          ],
        },
        { maxTokens: JUDGE_MAX_TOKENS, temperature: 0, signal: ctx.signal },
      );
      if (reply.stopReason === "error" || reply.stopReason === "aborted")
        return undefined;
      const text = reply.content
        .filter((part) => part.type === "text")
        .map((part) => part.text)
        .join("\n");
      return parseVerdict(text);
    } catch {
      return undefined;
    }
  };

  /** The message that keeps the turn going. */
  const nudge = (judgment?: Judgment) => {
    const head = judgment ? `Goal not yet met — ${judgment.reason}\n\n` : "";
    const rules = interactive
      ? `Call ${TOOL_NAME} when you believe the goal is met; the evaluator confirms it. Ask the user if you need input.`
      : `Call ${TOOL_NAME} when you believe the goal is met; the evaluator confirms it. Do not ask the user.`;
    return [
      `${head}Goal: ${oneLine(goal, 200)}`,
      "",
      "Take the next concrete step, then surface its evidence: run the check the goal names and show the result. The evaluator only reads the transcript.",
      rules,
    ].join("\n");
  };

  // Registered inactive: zero prompt/tool cost until /loop on.
  pi.registerTool({
    name: TOOL_NAME,
    label: "Loop Done",
    description:
      "Declare the loop finished: the task is complete and verified, or every option is exhausted.",
    promptSnippet: "Declare the loop finished when the task is complete",
    promptGuidelines: [
      `Loop mode is active: keep working across turns until you call ${TOOL_NAME}.`,
      `Call ${TOOL_NAME} only when the task is complete, or every option is exhausted; when blocked, name the blocker and the approaches already ruled out.`,
    ],
    defaultActive: false,
    // Active only while looping, so this hook is the loop's own switch: with
    // interactive off, the question tool leaves the declared tool list (and its
    // prompt guidelines) without touching the session's active tool set. The
    // `tool_call` guard below still blocks a direct or nested call by name.
    prepareLoadout: () =>
      active && !interactive
        ? { hiddenDeclarations: [QUESTION_TOOL] }
        : undefined,
    parameters: Type.Object({
      reason: Type.Optional(
        Type.String({
          description:
            "Why you are done: the outcome, or the blocker plus the options already ruled out.",
        }),
      ),
    }),

    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      claimed = true;
      const reason = params.reason?.trim();
      const why = reason ? `: ${reason}` : "";
      const text =
        `Completion submitted${why}. The evaluator checks the transcript against the goal; ` +
        "if it disagrees you get its reason and keep working.";
      return {
        content: [{ type: "text", text }],
        details: { reason },
        terminate: true,
      };
    },
  });

  pi.registerCommand("loop", {
    description:
      "Loop until a goal is met: /loop [goal] | /loop | " +
      ACTIONS.map((action) => `/loop ${action}`).join(" | "),
    getArgumentCompletions: (prefix) =>
      ACTIONS.filter((value) => value.startsWith(prefix)).map((value) => ({
        value,
        label: value,
      })),
    handler: (args, ctx) => {
      const text = args.trim();

      if (text === "off") {
        if (active)
          return stop(
            ctx,
            `Loop stopped manually after ${iterations} loop(s).`,
          );
        return ctx.ui.notify("Loop is not running.", "info");
      }

      if (text === "interactive") {
        interactive = !interactive;
        renderStatus(ctx);
        return ctx.ui.notify(
          `Loop interactivity: ${interactive ? "on" : "off"}.`,
          "info",
        );
      }

      // `/loop <goal>` starts, and like /goal the condition is the directive.
      if (text) {
        start(ctx, clip(text, GOAL_LIMIT));
        if (!ctx.isIdle())
          return ctx.ui.notify(
            "Current turn is still running; the goal applies from the next turn.",
            "info",
          );
        pi.sendUserMessage(text);
        return;
      }

      // Bare /loop: the current state.
      if (!active)
        return ctx.ui.notify(
          "Loop is off. Start it with /loop [goal].",
          "info",
        );
      const verdict = lastJudgment
        ? `\nLast verdict: ${lastJudgment.verdict.replace("_", " ")} — ${lastJudgment.reason}`
        : "";
      ctx.ui.notify(`${progress()}\nGoal: ${goal}${verdict}`, "info");
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

  // Prompt rules live here because this fires once per run, so the goal text is
  // stable and stays on the cached prefix; the per-turn nudge restates it.
  pi.on("before_agent_start", (event) => {
    if (!active) return;
    const guidelines = event.systemPromptOptions.promptGuidelines;
    if (goal)
      guidelines.push(
        `Goal mode is active. The loop runs until this condition is met: ${goal}`,
        "Prove progress with tool output: run the check the goal names and show its result. An independent evaluator reads only the transcript, so an unverified claim does not count.",
        `If the condition cannot be met, call ${TOOL_NAME} and name the concrete blocker.`,
      );
    if (!interactive)
      guidelines.push(
        "Loop mode is running with interactive off: do not ask the user anything and do not wait for approval. " +
          "ask_user is disabled. Pick the most reasonable option, state the " +
          `assumption, and keep working until you call ${TOOL_NAME}.`,
      );
  });

  // The whole loop: fires only when the run would otherwise end.
  pi.on("agent_before_settle", async (event, ctx) => {
    if (!active) return;
    // Aborted runs normally skip this boundary; treat a late abort as a stop.
    if (event.outcome === "aborted") return stop(ctx);
    // Do NOT gate on event.context.canContinue: it is computed before the entries
    // we return are committed, so it is false whenever the last message is the
    // assistant's — exactly the case we are here to handle. Pi re-checks it.

    // A turn that only talked is a turn the loop cannot build on.
    const acted = lastAssistant(event.context.contextMessages)?.content.some(
      (part) => part.type === "toolCall",
    );
    idleTurns = acted ? 0 : idleTurns + 1;
    if (idleTurns >= IDLE_LIMIT)
      return stop(ctx, `Loop stopped: ${IDLE_LIMIT} turns with no tool call.`);

    const judgment = await judge(ctx, event.context.llmMessages);
    if (judgment) lastJudgment = judgment;
    // Verdicts are shown: they explain why the loop kept going.
    const entry = (content: string, visible = true) => ({
      type: "custom_message" as const,
      customType: visible ? "loop-goal" : "loop-continue",
      content,
      display: visible,
    });

    if (judgment?.verdict === "met" || judgment?.verdict === "impossible") {
      const met = judgment.verdict === "met";
      stop(
        ctx,
        met
          ? `Goal met after ${iterations} loop(s).`
          : `Goal cannot be met: ${judgment.reason}`,
      );
      const headline = met ? "**Goal met.**" : "**Goal cannot be met.**";
      return {
        entries: [...event.entries, entry(`${headline} ${judgment.reason}`)],
      };
    }

    if (claimed) {
      claimed = false;
      // Without a verdict to overrule it, the claim stands.
      if (!judgment) return stop(ctx, "Loop stopped by agent.");
    }

    if (iterations >= LOOP_CAP)
      return stop(ctx, `Loop stopped at the ${LOOP_CAP}-loop cap.`);

    iterations += 1;
    renderStatus(ctx);
    return {
      entries: [
        ...event.entries,
        judgment ? entry(nudge(judgment)) : entry(nudge(), false),
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
