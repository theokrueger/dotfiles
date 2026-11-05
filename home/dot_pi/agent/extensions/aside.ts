/**
 * `/aside` — ask a side question without touching the main thread.
 *
 *   /aside why is the retry backoff capped at 30s here?
 *
 * The aside is a separate request to the active model with a snapshot of the
 * main thread's context (compaction and context edits applied, same system
 * prompt, same thinking level) plus the question. It has no tools, so it can
 * only reason over that context.
 *
 * It runs in the background, so one can be fired while the main agent is still
 * working. Answers land in the transcript as `custom` entries: rendered, but
 * never part of the LLM context, so the main thread stays on task.
 *
 * The request goes straight to the provider through the model registry, so it
 * starts no agent run: no `agent_*` events, no notifications, no turns.
 */

import {
  convertToLlm,
  getMarkdownTheme,
  type ExtensionAPI,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Box, Markdown, Text } from "@earendil-works/pi-tui";

const ENTRY_TYPE = "aside";
const WIDGET_KEY = "aside";
const PAINT_INTERVAL_MS = 100; // setWidget repaints the whole TUI
const PREVIEW_WIDTH = 100;

const INSTRUCTION = `

# Aside mode

This request is an aside: a side question about the conversation above, asked while the main thread may still be running. You have no tools here, so answer from the conversation and your own knowledge only. If the answer depends on something you cannot see, say what you would need to check. Be concise and direct: no plan, no preamble, no pretending you inspected or ran anything.`;

/** The main thread's last request may still be unanswered: keep the aside unmistakable. */
const ASK = (question: string) =>
  `Side question about the conversation above — answer this only, not the main task:\n\n${question}`;

interface Aside {
  id: number;
  question: string;
  model: string;
  startedAt: number;
  text: string;
  abort: AbortController;
}

interface AsideEntry {
  question: string;
  answer: string;
  error?: string;
  model: string;
  seconds: number;
  usage?: { input: number; output: number; cost: number };
}

const oneLine = (text: string, max = PREVIEW_WIDTH) => {
  const flat = text.replace(/\s+/g, " ").trim();
  return flat.length > max ? `${flat.slice(0, max - 1)}…` : flat;
};

/** The model's current line: what the aside is writing right now. */
const lastLine = (text: string) =>
  oneLine(
    text
      .split("\n")
      .filter((line) => line.trim())
      .pop() ?? "",
  );

export default function (pi: ExtensionAPI) {
  const running = new Map<number, Aside>();
  /** Answers finished mid-run: a custom entry appended then would reparent the streaming reply. */
  const pending: AsideEntry[] = [];
  let nextId = 0;
  let paintedAt = 0;

  const paint = (ctx: ExtensionContext, force = false) => {
    if (Date.now() - paintedAt < PAINT_INTERVAL_MS && !force) return;
    paintedAt = Date.now();
    const lines = [...running.values()].flatMap((aside) => [
      `aside #${aside.id} · ${aside.model} · ${((Date.now() - aside.startedAt) / 1000).toFixed(1)}s · ${oneLine(aside.question, 60)}`,
      `  ${lastLine(aside.text) || "waiting for the model…"}`,
    ]);
    try {
      ctx.ui.setWidget(WIDGET_KEY, lines.length ? lines : undefined, { placement: "aboveEditor" });
    } catch {
      // Session is going away.
    }
  };

  const finish = (ctx: ExtensionContext, entry: AsideEntry) => {
    if (ctx.mode === "tui" && !ctx.isIdle()) pending.push(entry);
    else pi.appendEntry<AsideEntry>(ENTRY_TYPE, entry);
  };

  const ask = async (ctx: ExtensionContext, aside: Aside): Promise<AsideEntry> => {
    const model = ctx.model;
    if (!model) throw new Error("no active model");

    const messages = [
      ...convertToLlm(ctx.sessionManager.buildSessionContext().messages),
      {
        role: "user" as const,
        content: [{ type: "text" as const, text: ASK(aside.question) }],
        timestamp: Date.now(),
      },
    ];

    const stream = ctx.modelRegistry.streamSimple(
      model,
      { systemPrompt: `${ctx.getSystemPrompt()}\n${INSTRUCTION}`, messages },
      {
        reasoning: model.reasoning ? ctx.thinkingLevel : undefined,
        sessionId: ctx.sessionManager.getSessionId(), // shares the main thread's prompt cache
        signal: aside.abort.signal,
      },
    );

    for await (const event of stream) {
      if (event.type !== "text_delta") continue;
      aside.text += event.delta;
      paint(ctx);
    }

    const message = await stream.result();
    const answer = message.content.flatMap((part) => (part.type === "text" ? [part.text] : [])).join("");

    let error: string | undefined;
    if (message.stopReason === "aborted") error = "aborted";
    else if (message.stopReason === "error") error = message.errorMessage || "request failed";
    else if (!answer) error = "empty response";

    return {
      question: aside.question,
      answer: answer || aside.text,
      error,
      model: aside.model,
      seconds: (Date.now() - aside.startedAt) / 1000,
      usage:
        message.usage && {
          input: message.usage.input,
          output: message.usage.output,
          cost: message.usage.cost?.total ?? 0,
        },
    };
  };

  const submit = async (ctx: ExtensionContext, aside: Aside) => {
    let entry: AsideEntry;
    try {
      entry = await ask(ctx, aside);
    } catch (error) {
      // Failures become entries too: an aside never interrupts with a notification.
      entry = {
        question: aside.question,
        answer: "",
        error: error instanceof Error ? error.message : String(error),
        model: aside.model,
        seconds: (Date.now() - aside.startedAt) / 1000,
      };
    } finally {
      running.delete(aside.id);
      paint(ctx, true);
    }
    if (!aside.abort.signal.aborted) finish(ctx, entry);
  };

  pi.registerEntryRenderer<AsideEntry>(ENTRY_TYPE, (entry, { expanded }, theme) => {
    if (!entry.data) return undefined;
    const d = entry.data;
    const box = new Box(1, 1, (text) => theme.bg("customMessageBg", text));
    box.addChild(new Text(`${theme.fg("accent", theme.bold("aside"))} ${d.question}`, 0, 0));
    box.addChild(new Text(theme.fg("dim", `${d.model} · ${d.seconds.toFixed(1)}s`), 0, 0));
    if (d.answer.trim()) box.addChild(new Markdown(d.answer, 0, 1, getMarkdownTheme()));
    if (d.error) box.addChild(new Text(theme.fg("error", d.error), 0, 0));
    if (expanded && d.usage) {
      const u = d.usage;
      box.addChild(
        new Text(theme.fg("dim", `↑${u.input} ↓${u.output} $${u.cost.toFixed(4)} · not in the main context`), 0, 0),
      );
    }
    return box;
  });

  pi.registerCommand("aside", {
    description: "Ask a side question with the current context, without touching the main thread",
    handler: async (args, ctx) => {
      const question = args.trim();
      if (!question) {
        ctx.ui.notify("Usage: /aside <question>", "warning");
        return;
      }
      const model = ctx.model;
      if (!model) {
        ctx.ui.notify("/aside needs an active model", "error");
        return;
      }

      const aside: Aside = {
        id: ++nextId,
        question,
        model: `${model.provider}/${model.id}`,
        startedAt: Date.now(),
        text: "",
        abort: new AbortController(),
      };
      running.set(aside.id, aside);
      paint(ctx, true);

      const task = submit(ctx, aside);
      // TUI/RPC return control at once so the main thread is never blocked;
      // one-shot modes exit when the prompt settles and must wait for the answer.
      if (ctx.mode === "print" || ctx.mode === "json") await task;
      else void task;
    },
  });

  pi.on("agent_settled", () => {
    for (const entry of pending.splice(0)) pi.appendEntry<AsideEntry>(ENTRY_TYPE, entry);
  });

  pi.on("session_shutdown", () => {
    for (const aside of running.values()) aside.abort.abort();
    running.clear();
    pending.length = 0;
  });
}
