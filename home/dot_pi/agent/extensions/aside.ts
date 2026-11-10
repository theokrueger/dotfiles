/**
 * `/aside` — ask a side question without touching the main thread.
 *
 *   /aside why is the retry backoff capped at 30s here?
 *
 * A separate request to the active model with a snapshot of the main thread's
 * context: no tools, and nothing added to the conversation.
 */

import {
  convertToLlm,
  getMarkdownTheme,
  type ExtensionAPI,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Box, Markdown, Text } from "@earendil-works/pi-tui";

const ENTRY_TYPE = "aside";
const STATUS_KEY = "20aside";

const ASK = (question: string) => `# Aside

This is a side question about the conversation above, not a continuation of the main task: answer only this. You have no tools in this request, so answer from the conversation and your own knowledge. Be concise and direct — no plan, no preamble, no pretending you inspected or ran anything.

${question}`;

interface AsideEntry {
  question: string;
  answer: string;
  error?: string;
  model: string;
  seconds: number;
  usage?: { input: number; output: number; cost: number };
}

export default function (pi: ExtensionAPI) {
  const inflight = new Set<AbortController>();

  // Bold while any aside runs. A ctx captured before a session switch is stale
  // and throws, so a failed update must not escape.
  const renderStatus = (ctx: ExtensionContext) => {
    try {
      if (!ctx.hasUI) return;
      ctx.ui.setStatus(
        STATUS_KEY,
        inflight.size > 0 ? ctx.ui.theme.bold("aside running") : undefined,
      );
    } catch {
      // Session replaced mid-flight: there is no footer left to update.
    }
  };

  /** One aside. Transport failures reject; a bad response sets `error`. */
  const ask = async (
    ctx: ExtensionContext,
    question: string,
    startedAt: number,
    signal: AbortSignal,
  ): Promise<AsideEntry> => {
    const model = ctx.model;
    if (!model) throw new Error("/aside needs an active model");

    const message = await ctx.modelRegistry.complete(
      model,
      {
        systemPrompt: ctx.getSystemPrompt(),
        messages: [
          ...convertToLlm(ctx.sessionManager.buildSessionContext().messages),
          {
            role: "user" as const,
            content: [{ type: "text" as const, text: ASK(question) }],
            timestamp: Date.now(),
          },
        ],
      },
      {
        reasoning: model.reasoning ? ctx.thinkingLevel : undefined,
        sessionId: ctx.sessionManager.getSessionId(), // shares the main thread's prompt cache
        signal,
      },
    );

    const answer = message.content
      .flatMap((part) => (part.type === "text" ? [part.text] : []))
      .join("");

    let error: string | undefined;
    if (message.stopReason === "aborted") error = "aborted";
    else if (message.stopReason === "error")
      error = message.errorMessage || "request failed";
    else if (!answer) error = "empty response";

    return {
      question,
      answer,
      error,
      model: `${model.provider}/${model.id}`,
      seconds: (Date.now() - startedAt) / 1000,
      usage: message.usage && {
        input: message.usage.input,
        output: message.usage.output,
        cost: message.usage.cost?.total ?? 0,
      },
    };
  };

  const show = (ctx: ExtensionContext, entry: AsideEntry) => {
    if (ctx.mode === "tui") pi.appendEntry<AsideEntry>(ENTRY_TYPE, entry);
    else
      ctx.ui.notify(
        entry.error ?? entry.answer,
        entry.error ? "error" : "info",
      );
  };

  pi.registerEntryRenderer<AsideEntry>(
    ENTRY_TYPE,
    (entry, { expanded }, theme) => {
      if (!entry.data) return undefined;
      const d = entry.data;
      const box = new Box(1, 1, (text) => theme.bg("customMessageBg", text));
      box.addChild(
        new Text(
          `${theme.fg("accent", theme.bold("aside"))} ${d.question}`,
          0,
          0,
        ),
      );
      box.addChild(
        new Text(
          theme.fg("dim", `${d.model} · ${d.seconds.toFixed(1)}s`),
          0,
          0,
        ),
      );
      if (d.answer.trim())
        box.addChild(new Markdown(d.answer, 0, 1, getMarkdownTheme()));
      if (d.error) box.addChild(new Text(theme.fg("error", d.error), 0, 0));
      if (expanded && d.usage) {
        const u = d.usage;
        box.addChild(
          new Text(
            theme.fg(
              "dim",
              `↑${u.input} ↓${u.output} $${u.cost.toFixed(4)} · not in the main context`,
            ),
            0,
            0,
          ),
        );
      }
      return box;
    },
  );

  pi.registerCommand("aside", {
    description:
      "Ask a side question with the current context, without touching the main thread",
    handler: async (args, ctx) => {
      const question = args.trim();
      if (!question) {
        ctx.ui.notify("Usage: /aside <question>", "warning");
        return;
      }

      const startedAt = Date.now();
      const abort = new AbortController();
      inflight.add(abort);
      renderStatus(ctx);

      const run = async () => {
        try {
          const entry = await ask(ctx, question, startedAt, abort.signal);
          if (!abort.signal.aborted) show(ctx, entry);
        } catch (error) {
          if (abort.signal.aborted) return;
          const model = ctx.model;
          show(ctx, {
            question,
            answer: "",
            error: error instanceof Error ? error.message : String(error),
            model: model ? `${model.provider}/${model.id}` : "no active model",
            seconds: (Date.now() - startedAt) / 1000,
          });
        } finally {
          inflight.delete(abort);
          renderStatus(ctx);
        }
      };

      // TUI/RPC return control at once so the main thread is never blocked;
      // one-shot modes exit when the prompt settles and must wait for the answer.
      const task = run();
      if (ctx.mode === "print" || ctx.mode === "json") await task;
      else void task;
    },
  });

  pi.on("session_shutdown", () => {
    for (const abort of inflight) abort.abort();
    inflight.clear();
  });
}
