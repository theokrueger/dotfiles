/**
 * Running a subagent.
 *
 * Each run is its own `pi --mode json --print` process, so it gets a fresh
 * context window plus the tool allowlist, model, and prompt from its markdown
 * file. Only the child's last assistant message is read back.
 *
 * JSON mode exits 0 even when the run failed, so the final message decides the
 * status, not the exit code. A wall-clock timeout and an output cap keep a model
 * that loops from pinning the parent session; each comes from the agent's
 * frontmatter and falls back to the defaults below.
 */

import { spawn } from "node:child_process";

import type { ThinkingLevel } from "@earendil-works/pi-agent-core";
import type { AssistantMessage } from "@earendil-works/pi-ai";

import type { AgentConfig } from "./agents.ts";

/** Defaults for an agent that pins no budget in its frontmatter. */
const DEFAULT_TIMEOUT_MINUTES = 10;
const DEFAULT_MAX_OUTPUT = 40_000;
/** Only the tail of stderr matters: the useful part of a failure is at the end. */
const MAX_STDERR = 2_000;
/** Match the TPS footer's fallback estimate while usage is still unreported. */
const CHARS_PER_TOKEN = 4;
/** A grandchild can hold stdout open after pi exits; stop waiting after this. */
const DRAIN_MS = 1_000;

export interface Outcome {
  agent: string;
  status: "completed" | "failed" | "aborted";
  /** Final assistant text, or the partial text of a run that failed late. */
  output: string;
  error?: string;
  turns: number;
  cost: number;
  durationMs: number;
}

export interface RunOptions {
  agent: AgentConfig;
  task: string;
  cwd: string;
  /** Parent model, used only when the agent does not pin its own. */
  model?: string;
  thinking?: ThinkingLevel;
  signal?: AbortSignal;
  /**
   * Token deltas from the child, for the session-wide TPS footer. Negative
   * values correct a char-based overestimate once `message_end` reports usage.
   */
  onTokens?: (tokens: number) => void;
}

/** What the child has said so far. */
interface State {
  output: string;
  stderr: string;
  turns: number;
  cost: number;
  timedOut: boolean;
  aborted: boolean;
  stopReason?: AssistantMessage["stopReason"];
  errorMessage?: string;
}

export async function runSubagent(options: RunOptions): Promise<Outcome> {
  const startedAt = Date.now();
  const timeoutMs = (options.agent.timeout ?? DEFAULT_TIMEOUT_MINUTES) * 60_000;
  const maxOutput = options.agent.maxOutput ?? DEFAULT_MAX_OUTPUT;
  const state: State = {
    output: "",
    stderr: "",
    turns: 0,
    cost: 0,
    timedOut: false,
    aborted: false,
  };
  const finish = (status: Outcome["status"], error?: string): Outcome => ({
    agent: options.agent.name,
    status,
    output: clamp(state.output, maxOutput),
    error,
    turns: state.turns,
    cost: state.cost,
    durationMs: Date.now() - startedAt,
  });

  if (options.signal?.aborted) return finish("aborted", "Aborted before starting");

  let code: number | null;
  try {
    code = await runProcess(options, state, timeoutMs);
  } catch (error) {
    return finish("failed", error instanceof Error ? error.message : String(error));
  }

  const { status, error } = verdict(code, state, timeoutMs);
  return finish(status, error);
}

/** The run's status, decided by its state and the child's exit code. */
function verdict(
  code: number | null,
  state: State,
  timeoutMs: number,
): { status: Outcome["status"]; error?: string } {
  if (state.timedOut) {
    return { status: "failed", error: `Timed out after ${timeoutMs / 60_000} minutes` };
  }
  if (state.aborted) return { status: "aborted", error: "Subagent was aborted" };
  if (code !== 0) {
    return { status: "failed", error: failure(state) ?? `pi exited with code ${code}` };
  }

  switch (state.stopReason) {
    case "aborted":
      return { status: "aborted", error: state.errorMessage || "Subagent aborted itself" };
    case "error":
      return {
        status: "failed",
        error: state.errorMessage || "The subagent's model request failed",
      };
    case "length":
      return { status: "failed", error: "Subagent output was truncated at the model's token limit" };
    default:
      break;
  }

  return state.output
    ? { status: "completed" }
    : { status: "failed", error: failure(state) ?? "Subagent finished without a message" };
}

function failure(state: State): string | undefined {
  if (state.errorMessage) return state.errorMessage;
  const line = state.stderr.split("\n").find((line) => line.trim());
  return line?.trim();
}

/** The child's argv. The task is prefixed so it cannot be read as a flag. */
function invocation(options: RunOptions): { command: string; args: string[] } {
  const args = ["--mode", "json", "--print", "--no-session", "--no-extensions"];
  const model = options.agent.model ?? options.model;
  if (model) args.push("--model", model);
  if (options.thinking) args.push("--thinking", options.thinking);
  if (options.agent.tools?.length) args.push("--tools", options.agent.tools.join(","));
  if (options.agent.systemPrompt) args.push("--append-system-prompt", options.agent.systemPrompt);
  args.push(`Task: ${options.task}`);

  // pi's own entry script when running inside pi, `pi` on PATH otherwise.
  const entry = process.argv[1] ?? "";
  return entry.includes("@earendil-works/pi-coding-agent")
    ? { command: process.execPath, args: [entry, ...args] }
    : { command: "pi", args };
}

/** Spawn the child, fold its events into `state`, resolve with its exit code. */
function runProcess(options: RunOptions, state: State, timeoutMs: number): Promise<number | null> {
  return new Promise<number | null>((resolve, reject) => {
    const { command, args } = invocation(options);
    const detached = process.platform !== "win32";
    let proc: ReturnType<typeof spawn>;

    try {
      proc = spawn(command, args, {
        cwd: options.cwd,
        detached,
        stdio: ["ignore", "pipe", "pipe"],
        env: childEnv(),
      });
    } catch (error) {
      reject(error);
      return;
    }

    /** The child leads its own process group, so its tool subprocesses die too. */
    const running = () => proc.exitCode === null && proc.signalCode === null;
    const stop = () => {
      if (!running() || !proc.pid) return;
      try {
        process.kill(detached ? -proc.pid : proc.pid, "SIGKILL");
      } catch {
        // Already gone.
      }
    };

    const timer = setTimeout(() => {
      if (!running()) return;
      state.timedOut = true;
      stop();
    }, timeoutMs);

    const onAbort = () => {
      if (!running()) return;
      state.aborted = true;
      stop();
    };
    options.signal?.addEventListener("abort", onAbort);

    const read = trackEvents(options, state);

    let buffer = "";
    let settled = false;
    const settle = (code: number | null) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      options.signal?.removeEventListener("abort", onAbort);
      resolve(code);
    };

    proc.stdout?.on("data", (chunk: Buffer) => {
      buffer += chunk.toString();
      const lines = buffer.split("\n");
      buffer = lines.pop() ?? "";
      for (const line of lines) read(line);
    });
    proc.stderr?.on("data", (chunk: Buffer) => {
      state.stderr = (state.stderr + chunk.toString()).slice(-MAX_STDERR);
    });
    proc.on("error", (error) => {
      clearTimeout(timer);
      options.signal?.removeEventListener("abort", onAbort);
      reject(error);
    });
    // `close` is the normal end: the pipes are drained. `exit` settles a run
    // whose grandchild kept a pipe open, so the timeout is not the only escape.
    proc.on("close", (code) => {
      if (buffer.trim()) read(buffer);
      settle(code);
    });
    proc.on("exit", (code) => setTimeout(() => settle(code), DRAIN_MS));
  });
}

/** Fold one child's JSONL lines into `state`. */
function trackEvents(options: RunOptions, state: State) {
  /** Characters streamed in the current assistant turn, for the token estimate. */
  let chars = 0;
  /** Tokens already forwarded for the current turn. */
  let forwarded = 0;

  const forward = (tokens: number) => {
    if (tokens !== 0) options.onTokens?.(tokens);
  };

  const trackMessage = (message: AssistantMessage) => {
    state.turns += 1;
    state.cost += message.usage?.cost?.total ?? 0;
    state.stopReason = message.stopReason;
    state.errorMessage = message.errorMessage ?? state.errorMessage;

    const said = assistantText(message);
    if (said) state.output = said;

    // The child streams in another process, so the parent mirrors its token
    // accounting: forward the provider's real output count and undo any
    // char-based overestimate left over from the streaming updates.
    const tokens = message.usage?.output ?? 0;
    if (tokens > 0) forward(tokens - forwarded);
    chars = 0;
    forwarded = 0;
  };

  return (line: string) => {
    const record = parseLine(line);
    if (!record) return;

    if (record.type === "message_update") {
      const delta = (record.assistantMessageEvent as { delta?: unknown } | undefined)?.delta;
      if (typeof delta === "string" && delta) chars += delta.length;

      // JSONL drops `partial`, but each record carries the message's cumulative
      // usage, which wins over the chars/4 estimate as soon as it appears.
      const reported = (record.usage as { output?: unknown } | undefined)?.output;
      const usage = typeof reported === "number" && Number.isFinite(reported) ? reported : 0;
      const total = Math.max(usage, chars / CHARS_PER_TOKEN);
      if (total > forwarded) {
        forward(total - forwarded);
        forwarded = total;
      }
      return;
    }

    const message = assistantMessage(record);
    if (message) trackMessage(message);
  };
}

/** Decode one JSONL record; undefined for a blank or malformed line. */
function parseLine(line: string): Record<string, unknown> | undefined {
  if (!line.trim()) return undefined;

  let value: unknown;
  try {
    value = JSON.parse(line);
  } catch {
    return undefined;
  }

  return typeof value === "object" && value !== null
    ? (value as Record<string, unknown>)
    : undefined;
}

/** The assistant message carried by a `message_end` record, if it has one. */
function assistantMessage(record: Record<string, unknown>): AssistantMessage | undefined {
  const message = record.message as { role?: unknown; content?: unknown } | undefined;
  if (record.type !== "message_end" || message?.role !== "assistant") return undefined;
  if (!Array.isArray(message.content)) return undefined;
  // SAFETY: JSONL boundary. Pi writes `message_end` records whose `message` is an
  // AssistantMessage; the checks above prove the role and content shape, and every
  // other field this module reads is accessed optionally.
  return message as unknown as AssistantMessage;
}

function assistantText(message: AssistantMessage): string {
  return message.content
    .filter((part) => part.type === "text")
    .map((part) => part.text)
    .join("\n")
    .trim();
}

function clamp(text: string, maxOutput: number): string {
  if (text.length <= maxOutput) return text;
  return `${text.slice(0, maxOutput)}\n\n[Output truncated: ${text.length - maxOutput} characters omitted.]`;
}

/** The child inherits credentials and config; only the session identity is dropped. */
function childEnv(): NodeJS.ProcessEnv {
  const { PI_SESSION_ID: _id, PI_SESSION_PATH: _path, ...env } = process.env;
  return env;
}
