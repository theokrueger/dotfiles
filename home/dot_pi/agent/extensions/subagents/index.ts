/**
 * Subagents — delegate a task to a specialized child agent.
 *
 *   subagent({ agent: "scout", task: "Map how session persistence works." })
 *   subagent({ agent: "scout", task: "...", background: true })
 *
 * The child runs in its own context window, so its searches and file reads never
 * enter this conversation; only its final summary comes back. Sibling calls in one
 * message run in parallel, so the schema needs no `tasks` array.
 *
 * Everything about a subagent lives in a markdown file (see agents/ and README.md).
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

import { discoverAgents, formatCatalog } from "./agents.ts";
import { type Outcome, runSubagent } from "./dispatch.ts";

const STATUS_KEY = "30subagents";
/** Session bus channel the TPS footer listens on (see tokens-per-sec.ts). */
const TPS_EVENT = "tps:tokens";
const RESULT_TYPE = "subagent-result";
const ICON = { completed: "✓", aborted: "■", failed: "✗" };

export default function (pi: ExtensionAPI) {
  /** Runs in flight, foreground and background; its value is the footer count. */
  let inflight = 0;
  /** Background runs outlive their turn, so they own a controller to stop them. */
  const background = new Set<AbortController>();
  // Background runs finish outside a tool call, so keep the newest context for the footer.
  let lastCtx: ExtensionContext | undefined;

  // Extension statuses render in the footer's default (light) text color, so the
  // label is passed through unwrapped — no dim/bold.
  const paint = () => {
    if (!lastCtx) return;
    const count = inflight;
    try {
      lastCtx.ui.setStatus(
        STATUS_KEY,
        count > 0 ? `${count} subagent(s)` : undefined,
      );
    } catch {
      // Session replaced mid-flight: there is no footer left to update.
    }
  };

  const end = () => {
    inflight = Math.max(0, inflight - 1);
    paint();
  };

  /** Hand a finished background run back to the session as a message. */
  const deliver = (outcome: Outcome) => {
    try {
      pi.sendMessage(
        {
          customType: RESULT_TYPE,
          content: `Background subagent finished.\n\n${summarize(outcome)}`,
          display: true,
          details: { ...outcome },
        },
        // Start a turn when idle; queue behind the current one when busy.
        { triggerTurn: true, deliverAs: "followUp" },
      );
    } catch {
      // Session replaced or shutting down: the result has nowhere to go.
    }
  };

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description: [
      "Delegate one task to a specialized subagent. It runs in its own context window and returns only its final summary,",
      "so its searches, file reads, and tool output never enter this conversation.",
      "",
      "Available subagents:",
      formatCatalog(discoverAgents()),
      "",
      "Call this tool several times in one message to run subagents in parallel.",
      "Give each subagent a self-contained task: it cannot see this conversation.",
      "Set background: true to keep working while it runs; its result then arrives as a message.",
    ].join("\n"),
    parameters: Type.Object({
      agent: Type.String({ description: "Name of the subagent to run." }),
      task: Type.String({
        description:
          "Self-contained instruction for the subagent. Include the files or symbols to start from, constraints, and the exact shape of the answer you need back.",
      }),
      background: Type.Optional(
        Type.Boolean({
          description:
            "Return immediately and deliver the result as a message when it finishes. Default: false, which waits for the summary.",
        }),
      ),
    }),

    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const agents = discoverAgents();
      const agent = agents.find(
        (candidate) => candidate.name === params.agent.trim(),
      );
      if (!agent) {
        const known = agents.map((entry) => entry.name).join(", ") || "(none)";
        return {
          content: [
            {
              type: "text" as const,
              text: `✗ ${params.agent} failed\n\nUnknown subagent. Available: ${known}.`,
            },
          ],
          details: { agent: params.agent, status: "failed" as const },
          isError: true,
        };
      }

      const options = {
        agent,
        task: params.task,
        cwd: ctx.cwd,
        model: ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined,
        // A pinned thinking level wins; otherwise inherit, but only when the model is inherited too.
        thinking:
          agent.thinking ?? (agent.model ? undefined : ctx.thinkingLevel),
        // The child is another process with its own (disabled) bus, so forward
        // its output tokens here for the session-wide TPS footer.
        onTokens: (tokens: number) =>
          pi.events.emit(TPS_EVENT, {
            tokens,
            source: `subagent:${agent.name}`,
          }),
      };

      lastCtx = ctx;
      inflight += 1;
      paint();

      if (params.background) {
        const controller = new AbortController();
        background.add(controller);
        void runSubagent({ ...options, signal: controller.signal })
          .then(deliver)
          .finally(() => {
            background.delete(controller);
            end();
          });
        return {
          content: [
            {
              type: "text" as const,
              text: `▶ ${agent.name} running in the background\nIts result will arrive as a message.`,
            },
          ],
          details: { agent: agent.name, status: "running" as const },
        };
      }

      try {
        return report(await runSubagent({ ...options, signal }));
      } finally {
        end();
      }
    },
  });

  // Background runs are not tied to the turn that started them.
  pi.on("session_shutdown", () => {
    for (const controller of background) controller.abort();
    background.clear();
    inflight = 0;
    paint();
  });
}

/** Header plus body: the whole result in one string, for tool results and messages. */
function summarize(outcome: Outcome): string {
  const turns = `${outcome.turns} ${outcome.turns === 1 ? "turn" : "turns"}`;
  const header = `${ICON[outcome.status]} ${outcome.agent} ${outcome.status} · ${duration(
    outcome.durationMs,
  )} · ${turns} · $${outcome.cost.toFixed(4)}`;
  // A run that failed late still shows what it managed to say.
  const body =
    [outcome.error, outcome.output].filter(Boolean).join("\n\n") ||
    "(no output)";
  return `${header}\n\n${body}`;
}

function report(outcome: Outcome) {
  return {
    content: [{ type: "text" as const, text: summarize(outcome) }],
    details: { agent: outcome.agent, status: outcome.status },
    isError: outcome.status !== "completed",
  };
}

function duration(ms: number): string {
  if (ms < 1_000) return `${ms}ms`;
  if (ms < 60_000) return `${(ms / 1_000).toFixed(1)}s`;
  return `${Math.floor(ms / 60_000)}m${Math.round((ms % 60_000) / 1_000)}s`;
}
