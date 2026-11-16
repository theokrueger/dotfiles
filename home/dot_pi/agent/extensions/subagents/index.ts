/**
 * Subagents — delegate tasks to specialized child agents.
 *
 *   subagent({ agent: "scout", task: "Map how session persistence works." })
 *   subagent_await({ ids: ["scout-1"] })   // block only when you need the result
 *
 * Dispatch is non-blocking: `subagent` returns a handle as soon as the child is
 * spawned, so this session can keep working (or wait on several children at
 * once). Awaiting claims the result, so it arrives in the tool result and not
 * also as a message; a run nobody awaits reports back as a message when it ends.
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
/** Settled summaries stay readable by handle, but a long session must not keep all of them. */
const MAX_KEPT = 100;

/** One dispatched child, from spawn to summary. */
interface Run {
  id: string;
  agent: string;
  controller: AbortController;
  /** Resolves when the child exits; never rejects, because runSubagent reports failures. */
  promise: Promise<Outcome>;
  settled: boolean;
  outcome?: Outcome;
  /** A waiter claimed the result, so it must not also arrive as a message. */
  awaited: boolean;
  /** Whether the summary went out as a message, so an interrupted wait can finish the job. */
  delivered: boolean;
}

export default function (pi: ExtensionAPI) {
  /** Every run this session dispatched, by handle, including settled ones. */
  const runs = new Map<string, Run>();
  /** Runs outlive the turn that started them, so they own a controller to stop them. */
  const running = new Set<AbortController>();
  /** Runs in flight; its value is the footer count. */
  let inflight = 0;
  let seq = 0;
  // Runs finish outside a tool call, so keep the newest context for the footer.
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

  /** Hand a finished run that nobody awaited back to the session as a message. */
  const deliver = (run: Run) => {
    if (!run.outcome) return;
    run.delivered = true;
    try {
      pi.sendMessage(
        {
          customType: RESULT_TYPE,
          content: `Subagent ${run.id} finished.\n\n${summarize(run.id, run.outcome)}`,
          display: true,
          details: { ...run.outcome, id: run.id },
        },
        // Start a turn when idle; queue behind the current one when busy.
        { triggerTurn: true, deliverAs: "followUp" },
      );
    } catch {
      // Session replaced or shutting down: the result has nowhere to go.
    }
  };

  /** Forget the oldest settled handles first, never a run still in flight. */
  const prune = () => {
    if (runs.size <= MAX_KEPT) return;
    for (const [id, run] of runs) {
      if (runs.size <= MAX_KEPT) break;
      if (run.settled) runs.delete(id);
    }
  };

  /** Watch a dispatched run to its end: delivery, the footer, and the registry follow from it. */
  const launch = (run: Run) => {
    void run.promise
      .then((outcome) => {
        run.outcome = outcome;
        run.settled = true;
        // A waiter takes ownership of the result; everyone else gets a message.
        if (!run.awaited) deliver(run);
      })
      .finally(() => {
        running.delete(run.controller);
        end();
      });
  };

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description: [
      "Delegate one task to a specialized subagent. It runs in its own context window and returns only its final summary,",
      "so its searches, file reads, and tool output never enter this conversation.",
      "",
      "Dispatch is asynchronous: this returns immediately with a handle. Keep working, or call subagent_await with the",
      "handles when you need the summaries before continuing. A run you never await reports back as a message when it finishes.",
      "",
      "Available subagents:",
      formatCatalog(discoverAgents()),
      "",
      "Call this tool several times in one message to dispatch subagents in parallel.",
      "Give each subagent a self-contained task: it cannot see this conversation.",
    ].join("\n"),
    promptGuidelines: [
      "Use subagent_await with the handles from subagent when you need a dispatched subagent's summary before continuing.",
    ],
    parameters: Type.Object({
      agent: Type.String({ description: "Name of the subagent to run." }),
      task: Type.String({
        description:
          "Self-contained instruction for the subagent. Include the files or symbols to start from, constraints, and the exact shape of the answer you need back.",
      }),
    }),

    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
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
      const id = `${agent.name}-${++seq}`;
      const controller = new AbortController();
      const promise = runSubagent({ ...options, signal: controller.signal });
      const run: Run = {
        id,
        agent: agent.name,
        controller,
        promise,
        settled: false,
        awaited: false,
        delivered: false,
      };

      runs.set(id, run);
      prune();
      running.add(controller);
      inflight += 1;
      paint();

      launch(run);

      return {
        content: [
          {
            type: "text" as const,
            text: `▶ ${id} dispatched (${agent.name})\n\nRunning asynchronously. Call subagent_await with ["${id}"] to wait for the summary; otherwise it arrives as a message.`,
          },
        ],
        details: { id, agent: agent.name, status: "running" as const },
      };
    },
  });

  pi.registerTool({
    name: "subagent_await",
    label: "Await Subagents",
    description: [
      "Block until dispatched subagents finish, then return their summaries.",
      "Pass the handles returned by the subagent tool. Awaiting claims those results,",
      "so each arrives here once instead of also as a message. Runs keep going if you",
      "do not await them, or if the wait itself is interrupted.",
    ].join("\n"),
    parameters: Type.Object({
      ids: Type.Array(Type.String(), {
        minItems: 1,
        description:
          'Handles returned by the subagent tool, for example ["scout-1", "worker-1"].',
      }),
    }),

    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      lastCtx = ctx;
      const ids = [...new Set(params.ids.map((id) => id.trim()))].filter(
        Boolean,
      );
      const selected: Run[] = [];
      const unknown: string[] = [];
      for (const id of ids) {
        const run = runs.get(id);
        if (run) selected.push(run);
        else unknown.push(id);
      }

      if (selected.length === 0) {
        const known = [...runs.keys()].join(", ") || "(none)";
        return {
          content: [
            {
              type: "text" as const,
              text: `✗ No subagent to await\n\n${
                unknown.length > 0
                  ? `Unknown handle: ${unknown.join(", ")}.`
                  : "No handles were given."
              } Dispatched: ${known}.`,
            },
          ],
          details: { ids, status: "failed" as const },
          isError: true,
        };
      }

      // Claim before waiting: a fast run must not also deliver a message.
      for (const run of selected) run.awaited = true;

      const finished = await waitFor(selected, signal);
      if (!finished) {
        // Esc ends the wait, not the children: those still running go back to
        // message delivery, and a run that settled mid-abort is delivered now.
        for (const run of selected) {
          if (run.settled) {
            if (!run.delivered) deliver(run);
          } else {
            run.awaited = false;
          }
        }
        return {
          content: [
            {
              type: "text" as const,
              text: `⏸ Stopped waiting for ${selected.map((run) => run.id).join(", ")}\n\nThe subagents keep running; their summaries will arrive as messages.`,
            },
          ],
          details: { ids, status: "running" as const },
        };
      }

      const failed = finished.some(({ outcome }) => outcome.status !== "completed");
      const missing =
        unknown.length > 0
          ? `Unknown handle(s) ignored: ${unknown.join(", ")}.\n\n`
          : "";
      return {
        content: [
          {
            type: "text" as const,
            text:
              missing +
              finished
                .map(({ run, outcome }) => summarize(run.id, outcome))
                .join("\n\n---\n\n"),
          },
        ],
        details: {
          results: finished.map(({ run, outcome }) => ({
            id: run.id,
            agent: run.agent,
            status: outcome.status,
          })),
        },
        isError: failed,
      };
    },
  });

  // Runs are not tied to the turn that started them.
  pi.on("session_shutdown", () => {
    for (const controller of running) controller.abort();
    running.clear();
    runs.clear();
    inflight = 0;
    paint();
  });
}

/**
 * The awaited outcomes, or undefined when the turn was interrupted first.
 * Interruption only ends the wait: the runs themselves are left alone.
 */
function waitFor(
  runs: Run[],
  signal?: AbortSignal,
): Promise<{ run: Run; outcome: Outcome }[] | undefined> {
  const done = Promise.all(
    runs.map(async (run) => ({ run, outcome: await run.promise })),
  );
  if (!signal) return done;
  if (signal.aborted) return Promise.resolve(undefined);

  return new Promise<{ run: Run; outcome: Outcome }[] | undefined>((resolve) => {
    const onAbort = () => resolve(undefined);
    signal.addEventListener("abort", onAbort, { once: true });
    void done.then((results) => {
      signal.removeEventListener("abort", onAbort);
      resolve(results);
    });
  });
}

/** Header plus body: the whole result in one string, for tool results and messages. */
function summarize(id: string, outcome: Outcome): string {
  const turns = `${outcome.turns} ${outcome.turns === 1 ? "turn" : "turns"}`;
  const header = `${ICON[outcome.status]} ${id} ${outcome.status} · ${duration(
    outcome.durationMs,
  )} · ${turns} · $${outcome.cost.toFixed(4)}`;
  // A run that failed late still shows what it managed to say.
  const body =
    [outcome.error, outcome.output].filter(Boolean).join("\n\n") ||
    "(no output)";
  return `${header}\n\n${body}`;
}

function duration(ms: number): string {
  if (ms < 1_000) return `${ms}ms`;
  if (ms < 60_000) return `${(ms / 1_000).toFixed(1)}s`;
  return `${Math.floor(ms / 60_000)}m${Math.round((ms % 60_000) / 1_000)}s`;
}
