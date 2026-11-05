/**
 * ask_user — ask the user a question with optional multiple-choice answers.
 *
 * One dialog per question; `questions` asks 2-4 of them in sequence. Options, the
 * freeform field, and Done share one list, so a custom answer is typed inline
 * and multi-select toggles in place. Escape cancels the call, and `timeout`
 * cancels it after N milliseconds.
 */

import type {
  ExtensionAPI,
  ExtensionUIContext,
} from "@earendil-works/pi-coding-agent";
import {
  Input,
  Key,
  matchesKey,
  Text,
  truncateToWidth,
  visibleWidth,
  wrapTextWithAnsi,
} from "@earendil-works/pi-tui";
import { Type } from "typebox";

const BATCH_MIN = 2;
const BATCH_MAX = 4;
const FREEFORM_LABEL = "Type something different...";
const DONE_LABEL = "Done";

interface Choice {
  title: string;
  description?: string;
}

/** What the user picked for one question. */
type Response =
  | { kind: "selection"; selections: string[] }
  | { kind: "text"; text: string };

interface Answer {
  question: string;
  response: Response;
}

interface AskDetails {
  cancelled: boolean;
  answers: Answer[];
}

/** Fields shared by the top-level call and each `questions` entry. */
interface QuestionInput {
  question?: string;
  context?: string;
  options?: readonly Choice[];
  allowMultiple?: boolean;
  allowFreeform?: boolean;
}

interface AskParams extends QuestionInput {
  questions?: readonly QuestionInput[];
  timeout?: number;
}

/** The same input with defaults applied. */
interface Question {
  question: string;
  context?: string;
  options: Choice[];
  allowMultiple: boolean;
  allowFreeform: boolean;
}

const CANCELLED: AskDetails = { cancelled: true, answers: [] };

/** One uniform list of questions; a single question is a batch of one. */
function toQuestions(params: AskParams): Question[] {
  return (params.questions ?? [params]).map((input) => {
    const question = input.question?.trim();
    if (!question) throw new Error("ask_user needs a non-empty `question` string.");
    return {
      question,
      context: input.context?.trim() || undefined,
      options: (input.options ?? []).filter((choice) => choice.title.trim()),
      allowMultiple: input.allowMultiple === true,
      allowFreeform: input.allowFreeform !== false,
    };
  });
}

const formatResponse = (response: Response): string =>
  response.kind === "selection"
    ? response.selections.join(", ")
    : `"${response.text}"`;

function formatAnswers(answers: Answer[]): string {
  const [only, ...rest] = answers;
  if (only && rest.length === 0) {
    return `User answered: ${formatResponse(only.response)}`;
  }
  return (
    "User answered:\n" +
    answers
      .map(
        (answer, index) =>
          `${index + 1}. ${answer.question} → ${formatResponse(answer.response)}`,
      )
      .join("\n")
  );
}

/** Non-interactive sessions get the question in the error so the model can relay it. */
function describeRequest(questions: Question[]): string {
  const blocks = questions.map((entry, index) => {
    const prefix = questions.length > 1 ? `${index + 1}. ` : "";
    let text = `${prefix}${entry.question}`;
    if (entry.context) text += `\n\nContext:\n${entry.context}`;
    if (entry.options.length > 0) {
      text +=
        "\n\nOptions:\n" +
        entry.options
          .map(
            (choice) =>
              `- ${choice.title}${choice.description ? ` — ${choice.description}` : ""}`,
          )
          .join("\n");
    }
    if (entry.allowFreeform) text += "\n\nYou can also answer freely.";
    return text;
  });

  return `Ask requires interactive mode. Please answer:\n\n${blocks.join("\n\n")}`;
}

/** One row of the dialog: a choice, the inline freeform field, or Done. */
type Row =
  | { kind: "option"; index: number }
  | { kind: "freeform" }
  | { kind: "done" };

/**
 * One dialog for a question with choices. Options, the freeform field, and (for
 * multi-select) Done are rows of the same list: the freeform row is a live text
 * field, and toggling an option leaves the cursor where it is.
 */
function choiceDialog(
  ui: ExtensionUIContext,
  entry: Question,
  deadline: number | undefined,
  signal: AbortSignal | undefined,
): Promise<Response | null> {
  return ui.custom<Response | null>(
    (tui, theme, keybindings, done) => {
      const multi = entry.allowMultiple;
      const input = new Input({
        prompt: "",
        placeholder: FREEFORM_LABEL,
        placeholderStyle: (text) => theme.fg("dim", text),
      });
      const rows: Row[] = entry.options.map((_, index) => ({
        kind: "option",
        index,
      }));
      if (entry.allowFreeform) rows.push({ kind: "freeform" });
      if (multi) rows.push({ kind: "done" });

      const freeformRow = rows.findIndex((row) => row.kind === "freeform");
      const chosen = new Set<number>();

      let cursor = 0;
      let message: string | undefined;
      let focused = false;
      let closed = false;
      let cache: { width: number; lines: string[] } | undefined;
      // One timer closes the dialog on time; a ticker keeps the countdown fresh.
      let expiry: ReturnType<typeof setTimeout> | undefined;
      let ticker: ReturnType<typeof setInterval> | undefined;

      const row = () => rows[cursor];
      const refresh = () => {
        cache = undefined;
        tui.requestRender();
      };
      const clearTimers = () => {
        if (expiry !== undefined) clearTimeout(expiry);
        if (ticker !== undefined) clearInterval(ticker);
        signal?.removeEventListener("abort", onAbort);
      };
      const close = (result: Response | null) => {
        if (closed) return;
        closed = true;
        clearTimers();
        done(result);
      };
      const onAbort = () => close(null);

      const syncFocus = () => {
        input.focused = focused && row()?.kind === "freeform";
      };
      const move = (delta: number) => {
        cursor = (cursor + delta + rows.length) % rows.length;
        message = undefined;
        syncFocus();
        refresh();
      };
      const toggle = (index: number) => {
        if (chosen.has(index)) chosen.delete(index);
        else chosen.add(index);
        refresh();
      };
      const finish = () => {
        if (chosen.size === 0) {
          message = "Select at least one option first, or press escape to cancel.";
          refresh();
          return;
        }
        close({
          kind: "selection",
          selections: entry.options
            .filter((_, index) => chosen.has(index))
            .map((choice) => choice.title),
        });
      };
      const submit = () => {
        const current = row();
        if (current?.kind === "freeform") {
          const text = input.getValue().trim();
          if (text) close({ kind: "text", text });
          return;
        }
        if (current?.kind === "done") return finish();
        if (current?.kind !== "option") return;

        const choice = entry.options[current.index];
        if (!choice) return;
        if (multi) toggle(current.index);
        else close({ kind: "selection", selections: [choice.title] });
      };

      /** Printable input jumps into the freeform field instead of requiring Enter. */
      const typeInto = (data: string) => {
        if (freeformRow < 0 || data === " " || /^[\x00-\x1f\x7f]/.test(data)) {
          return;
        }
        cursor = freeformRow;
        message = undefined;
        syncFocus();
        input.handleInput(data);
        refresh();
      };

      const handleInput = (data: string) => {
        if (keybindings.matches(data, "tui.select.up")) return move(-1);
        if (keybindings.matches(data, "tui.select.down")) return move(1);
        if (keybindings.matches(data, "tui.select.confirm") || data === "\n") {
          return submit();
        }
        if (matchesKey(data, Key.escape)) {
          if (row()?.kind === "freeform" && input.getValue()) {
            input.setValue("");
            return refresh();
          }
          return close(null);
        }
        if (keybindings.matches(data, "tui.select.cancel")) return close(null);

        const current = row();
        if (current?.kind === "freeform") {
          input.handleInput(data);
          return refresh();
        }
        if (multi && data === " " && current?.kind === "option") {
          return toggle(current.index);
        }
        typeInto(data);
      };

      const render = (width: number): string[] => {
        if (cache?.width === width) return cache.lines;

        const lines: string[] = [];
        const add = (prefix: string, text: string) => {
          const indent = visibleWidth(prefix);
          const wrapped = wrapTextWithAnsi(text, Math.max(1, width - indent));
          const pad = " ".repeat(indent);
          wrapped.forEach((line, index) =>
            lines.push(`${index === 0 ? prefix : pad}${line}`),
          );
        };

        const countdown =
          deadline === undefined
            ? ""
            : theme.fg(
                "dim",
                ` (${Math.max(1, Math.ceil((deadline - Date.now()) / 1000))}s)`,
              );

        lines.push(theme.fg("dim", "─".repeat(width)));
        add(" ", theme.fg("accent", theme.bold(entry.question)) + countdown);
        if (entry.context) add(" ", theme.fg("dim", entry.context));
        lines.push("");

        rows.forEach((item, index) => {
          const active = index === cursor;
          const prefix = active ? theme.fg("accent", "→ ") : "  ";

          if (item.kind === "option") {
            const choice = entry.options[item.index];
            if (!choice) return;
            let box = "";
            if (multi) {
              box = chosen.has(item.index)
                ? theme.fg("success", "[x] ")
                : theme.fg("muted", "[ ] ");
            }
            add(prefix, box + theme.fg(active ? "accent" : "text", choice.title));
            if (choice.description) {
              add("     ", theme.fg("muted", choice.description));
            }
            return;
          }

          if (item.kind === "freeform") {
            const indent = visibleWidth(prefix);
            if (active) {
              const [line = ""] = input.render(Math.max(1, width - indent));
              lines.push(prefix + line);
            } else {
              const value = input.getValue();
              const label = value
                ? theme.fg("text", value)
                : theme.fg("dim", FREEFORM_LABEL);
              lines.push(
                prefix + truncateToWidth(label, Math.max(1, width - indent)),
              );
            }
            return;
          }

          const label =
            chosen.size > 0
              ? `${DONE_LABEL} (${chosen.size} selected)`
              : DONE_LABEL;
          add(prefix, theme.fg(active ? "accent" : "muted", label));
        });

        lines.push("");
        add(
          " ",
          theme.fg(
            "dim",
            multi
              ? "↑↓ move • space toggle • enter select • esc cancel"
              : "↑↓ move • enter select • esc cancel",
          ),
        );
        if (message) add(" ", theme.fg("warning", message));
        lines.push(theme.fg("dim", "─".repeat(width)));

        cache = { width, lines };
        return lines;
      };

      if (deadline !== undefined) {
        expiry = setTimeout(() => close(null), Math.max(1, deadline - Date.now()));
        ticker = setInterval(refresh, 1_000);
      }
      if (signal?.aborted) close(null);
      else signal?.addEventListener("abort", onAbort, { once: true });

      return {
        get focused() {
          return focused;
        },
        set focused(value: boolean) {
          focused = value;
          syncFocus();
        },
        render,
        handleInput,
        invalidate() {
          cache = undefined;
        },
        dispose: clearTimers,
      };
    },
    { blocked: { kind: "question", message: entry.question } },
  );
}

/** Ask one question. Returns null when the user cancels, times out, or aborts. */
function askOne(
  ui: ExtensionUIContext,
  entry: Question,
  deadline: number | undefined,
  signal: AbortSignal | undefined,
): Promise<Response | null> {
  if (signal?.aborted) return Promise.resolve(null);

  if (entry.options.length > 0) {
    return choiceDialog(ui, entry, deadline, signal);
  }

  // No options: the dialog is just one text field, so use the built-in input.
  const prompt = entry.context
    ? `${entry.question}\n\nContext:\n${entry.context}`
    : entry.question;
  const timeout =
    deadline === undefined ? undefined : Math.max(1, deadline - Date.now());
  return ui
    .input(prompt, "Type your answer...", { signal, timeout })
    .then((text) => {
      const value = text?.trim();
      return value ? { kind: "text", text: value } : null;
    });
}

export default function askUser(pi: ExtensionAPI) {
  // Flat object shape: union item schemas get stripped or rejected by several
  // providers/proxies, leaving the model to guess the shape.
  const optionSchema = Type.Object({
    title: Type.String({ description: "Short title for this option" }),
    description: Type.Optional(
      Type.String({ description: "Longer description explaining this option" }),
    ),
  });

  const parameters = Type.Object({
    question: Type.Optional(
      Type.String({
        description:
          "The question to ask the user. Use `question` for one question; for 2-4 questions use `questions` instead.",
      }),
    ),
    questions: Type.Optional(
      Type.Array(
        Type.Object({
          question: Type.String({ description: "One question in the batch" }),
          context: Type.Optional(
            Type.String({
              description:
                "Relevant context to show with this question (summary of findings)",
            }),
          ),
          options: Type.Optional(
            Type.Array(optionSchema, {
              description: "List of options for this question",
            }),
          ),
          allowMultiple: Type.Optional(
            Type.Boolean({
              description: "Allow selecting multiple options. Default: false",
            }),
          ),
          allowFreeform: Type.Optional(
            Type.Boolean({
              description: "Add a freeform text option. Default: true",
            }),
          ),
        }),
        {
          minItems: BATCH_MIN,
          maxItems: BATCH_MAX,
          description:
            "2-4 independent questions asked one after another, used instead of `question`. Set context, options, allowMultiple, and allowFreeform on each entry; `timeout` applies to the whole batch.",
        },
      ),
    ),
    context: Type.Optional(
      Type.String({
        description:
          "Relevant context to show before the question (summary of findings)",
      }),
    ),
    options: Type.Optional(
      Type.Array(optionSchema, {
        description: "List of options for the user to choose from",
      }),
    ),
    allowMultiple: Type.Optional(
      Type.Boolean({
        description: "Allow selecting multiple options. Default: false",
      }),
    ),
    allowFreeform: Type.Optional(
      Type.Boolean({
        description: "Add a freeform text option. Default: true",
      }),
    ),
    timeout: Type.Optional(
      Type.Number({
        description:
          "Cancel the whole call after N milliseconds and report it as cancelled.",
      }),
    ),
  });

  pi.registerTool({
    name: "ask_user",
    label: "Ask User",
    // Asks the user, so only the model may call it; codemode scripts cannot open prompts.
    exposure: "model-only",
    description:
      "Ask the user a question with optional multiple-choice answers. Use this to gather information interactively. Ask one focused question per call, or 2-4 independent questions together through `questions`. Before calling, gather context with tools (read/web/ref) and pass a short summary via the context field.",
    promptSnippet:
      "Ask the user one focused question (or 2-4 independent ones together) with optional multiple-choice answers to gather information interactively",
    promptGuidelines: [
      "Before calling ask_user, gather context with tools (read/web/ref) and pass a short summary via the context field.",
      "Use ask_user when the user's intent is ambiguous, when a decision requires explicit user input, or when multiple valid options exist.",
      "Ask one focused question per ask_user call by default.",
      "Use `questions` (2-4 entries) only for independent decisions whose prerequisites are already settled; ask anything that depends on another answer in a later ask_user call.",
      "With `questions`, put every question inside `questions`; there is no batch heading, so each entry must be self-contained.",
      "Do not combine multiple numbered, multipart, or unrelated questions into one question's text.",
    ],
    // Block other tool calls in the same turn until the user answers, so
    // side-effecting tools cannot run before the prompt is seen.
    executionMode: "sequential",
    parameters,

    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      const questions = toQuestions(params);
      if (!ctx.hasUI) throw new Error(describeRequest(questions));
      if (signal?.aborted) {
        return { content: [{ type: "text", text: "Cancelled" }], details: CANCELLED };
      }

      const batch = questions.length > 1;
      const deadline =
        params.timeout !== undefined && params.timeout > 0
          ? Date.now() + params.timeout
          : undefined;

      onUpdate?.({
        content: [{ type: "text", text: "Waiting for user input..." }],
        details: { cancelled: false, answers: [] },
      });

      const answers: Answer[] = [];
      for (const [index, entry] of questions.entries()) {
        const question = batch
          ? `(${index + 1}/${questions.length}) ${entry.question}`
          : entry.question;
        const response = await askOne(
          ctx.ui,
          { ...entry, question },
          deadline,
          signal,
        );
        if (!response) {
          return {
            content: [
              {
                type: "text",
                text: batch
                  ? "User cancelled the questions"
                  : "User cancelled the question",
              },
            ],
            details: CANCELLED,
          };
        }
        answers.push({ question: entry.question, response });
      }

      return {
        content: [{ type: "text", text: formatAnswers(answers) }],
        details: { cancelled: false, answers },
      };
    },

    // One muted line instead of the generic `ask_user question="…" questions=[…]`
    // header: the question itself, or the batch size.
    renderCall(args, theme) {
      const question =
        typeof args.question === "string" ? args.question.trim() : "";
      const count = Array.isArray(args.questions) ? args.questions.length : 0;
      const label = count > 0 ? `${count} question(s)` : question;
      return new Text(label ? theme.fg("muted", label) : "", 0, 0);
    },
  });
}
