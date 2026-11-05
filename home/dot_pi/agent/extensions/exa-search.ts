/**
 * web_search — Exa search over the public MCP endpoint.
 *
 * Exa returns ready-made result blocks (title, URL, published date,
 * highlights), so nothing is scraped locally. Anonymous calls work; an API key
 * (`/login exa` or EXA_API_KEY) only raises the rate limit.
 *
 * /search <query> runs a search by hand and queues the results for the next
 * turn without waking the model.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";

const MCP_URL = "https://mcp.exa.ai/mcp";
const PROVIDER_ID = "exa";
const STATUS_KEY = "exa-search";
const TIMEOUT_MS = 30_000;

type SearchArgs = {
  query: string;
  objective?: string;
  numResults?: number;
  apiKey?: string;
};

type SearchResult = { text: string; authenticated: boolean };

/** Details carried by the tool result and the `/search` message. */
type SearchDetails = { query: string; characters: number; authenticated: boolean };

/** The plain text of a tool result or custom message. */
function textOf(content: string | { type: string; text?: string }[]): string {
  if (typeof content === "string") return content;
  return content
    .filter((block) => block.type === "text" && typeof block.text === "string")
    .map((block) => block.text)
    .join("\n");
}

/** The subset of a JSON-RPC response this tool understands. */
type McpResponse = {
  result?: { content?: unknown[]; isError?: boolean };
  error?: { message?: string };
};

/** One JSON-RPC document, accepting either a plain body or an SSE frame. */
function parsePayload(body: string, contentType: string): McpResponse {
  let text = body;
  if (contentType.includes("text/event-stream")) {
    text =
      body
        .split("\n")
        .filter((line) => line.startsWith("data:"))
        .map((line) => line.slice(5).trim())
        .find((data) => data.length > 0 && data !== "[DONE]") ?? "";
  }

  let payload: unknown;
  try {
    payload = JSON.parse(text);
  } catch {
    throw new Error(`Exa MCP sent malformed response: ${body.slice(0, 200)}`);
  }
  if (typeof payload !== "object" || payload === null) {
    throw new Error("Exa MCP returned a non-object response");
  }
  return payload as McpResponse;
}

/** Collect the text blocks Exa returns, ignoring anything malformed. */
function textBlocks(content: unknown[] | undefined): string {
  if (!Array.isArray(content)) return "";
  return content
    .flatMap((block: unknown) => {
      if (typeof block !== "object" || block === null) return [];
      const { type, text } = block as { type?: unknown; text?: unknown };
      return type === "text" && typeof text === "string" ? [text] : [];
    })
    .join("\n\n")
    .trim();
}

async function callExa(args: SearchArgs, signal?: AbortSignal): Promise<SearchResult> {
  const timeout = AbortSignal.timeout(TIMEOUT_MS);
  const response = await fetch(MCP_URL, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      accept: "application/json, text/event-stream",
      // Anonymous calls work; a key only lifts the free-tier quota.
      ...(args.apiKey ? { "x-api-key": args.apiKey } : {}),
    },
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: 1,
      method: "tools/call",
      params: {
        name: "web_search_exa",
        arguments: {
          query: args.query,
          objective: args.objective ?? args.query,
          numResults: Math.min(Math.max(args.numResults ?? 8, 1), 20),
        },
      },
    }),
    signal: signal ? AbortSignal.any([signal, timeout]) : timeout,
  });

  const body = await response.text();
  if (!response.ok) {
    const hint =
      response.status === 429
        ? `Exa free-tier limit hit; run /login ${PROVIDER_ID} to raise it. `
        : response.status === 401 || response.status === 403
          ? `Exa rejected the key; run /login ${PROVIDER_ID}. `
          : "";
    throw new Error(`${hint}${response.status} ${response.statusText}: ${body.slice(0, 200)}`);
  }

  const payload = parsePayload(body, response.headers.get("content-type") ?? "");
  if (payload.error) throw new Error(payload.error.message ?? "Exa MCP error");

  const text = textBlocks(payload.result?.content);
  if (payload.result?.isError) throw new Error(text || "Exa MCP returned an error");
  if (!text) throw new Error("Exa MCP returned no results");
  return { text, authenticated: Boolean(args.apiKey) };
}

/** Key from `/login exa` (or EXA_API_KEY), or undefined for the free tier. */
function resolveApiKey(ctx: ExtensionContext): Promise<string | undefined> {
  return ctx.modelRegistry.getApiKeyForProvider(PROVIDER_ID);
}

export default function (pi: ExtensionAPI) {
  // A model-less provider purely so `/login exa` can store a key. The
  // `$EXA_API_KEY` reference also makes the env var a fallback source.
  pi.registerProvider(PROVIDER_ID, {
    name: "Exa",
    apiKey: "$EXA_API_KEY",
  });

  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description:
      "Search the web and get back clean result blocks (title, URL, published date, content highlights). " +
      "Describe the ideal page rather than keywords, e.g. 'blog post comparing React and Vue performance' " +
      "instead of 'React vs Vue'. Backed by Exa via the opencode-style MCP endpoint, so no results are parsed locally.",
    promptSnippet: "Search the web via Exa and get titles, URLs, and content highlights",
    promptGuidelines: [
      "Use web_search for current information, news, facts, or anything that needs live web results.",
      "web_search takes a natural-language description of the ideal page, not a keyword list.",
    ],
    parameters: Type.Object({
      query: Type.String({ description: "Natural-language description of the ideal page to find" }),
      objective: Type.Optional(
        Type.String({
          description:
            "What this search should achieve: which documents to rank first, what to exclude, which facts to extract (defaults to the query)",
        }),
      ),
      numResults: Type.Optional(
        Type.Number({ description: "How many results to return (1-20, default 8)" }),
      ),
    }),
    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      onUpdate?.({ content: [{ type: "text", text: `Searching: ${params.query}` }], details: {} });
      const result = await callExa({ ...params, apiKey: await resolveApiKey(ctx) }, signal);
      const details: SearchDetails = {
        query: params.query,
        characters: result.text.length,
        authenticated: result.authenticated,
      };
      return { content: [{ type: "text", text: result.text }], details };
    },
    renderResult(result, { expanded }, theme, context) {
      const text = textOf(result.content);
      if (expanded) {
        return new Text(
          text
            .split("\n")
            .map((line) => theme.fg("toolOutput", line))
            .join("\n"),
          0,
          0,
        );
      }
      const details = result.details as SearchDetails | undefined;
      const chars = details?.characters ?? text.length;
      const lines = text ? text.split("\n").length : 0;
      return new Text(
        theme.fg("success", `${chars} char(s)`) +
          theme.fg("dim", ` \u00b7 ${lines} line(s) \u00b7 `) +
          context.keyHint("app.tools.expand", "to expand"),
        0,
        0,
      );
    },
  });

  // Collapse the queued `/search` results the same way; expanding falls back to
  // pi's normal markdown rendering.
  pi.registerMessageRenderer<SearchDetails>("exa-search-results", (message, options, theme) => {
    if (options.expanded) return undefined;
    const chars = message.details?.characters ?? textOf(message.content).length;
    return new Text(
      theme.fg("accent", "web search") +
        theme.fg("dim", ` \u00b7 ${message.details?.query ?? "results"} \u00b7 ${chars} char(s) \u00b7 `) +
        options.keyHint("app.tools.expand", "to expand"),
      options.outputPad,
      0,
    );
  });

  /** Search, then queue the results for the next turn without triggering one. */
  async function runManualSearch(query: string, ctx: ExtensionContext): Promise<void> {
    ctx.ui.setStatus(STATUS_KEY, `searching: ${query.slice(0, 40)}`);
    try {
      const result = await callExa({ query, apiKey: await resolveApiKey(ctx) });
      const details: SearchDetails = {
        query,
        characters: result.text.length,
        authenticated: result.authenticated,
      };
      pi.sendMessage(
        {
          customType: "exa-search-results",
          content: [{ type: "text", text: `Web search results for: ${query}\n\n${result.text}` }],
          display: true,
          details,
        },
        { deliverAs: "nextTurn" },
      );
      ctx.ui.notify(
        `Exa: ${result.text.length} char(s) queued for the next turn` +
          (result.authenticated ? "" : " (free tier)"),
        "info",
      );
    } catch (error) {
      ctx.ui.notify(
        `Search failed: ${error instanceof Error ? error.message : String(error)}`,
        "error",
      );
    } finally {
      ctx.ui.setStatus(STATUS_KEY, undefined);
    }
  }

  // `/search <query>`: run a search by hand and drop the results into the
  // conversation, so a manual search costs one round trip instead of asking
  // the model to call the tool first.
  pi.registerCommand("search", {
    description: "Run an Exa web search now and queue the full results for the next turn",
    handler: async (args, ctx) => {
      const query =
        args.trim() ||
        (await ctx.ui.input("Web search", "describe the ideal page, not keywords"))?.trim();
      if (query) await runManualSearch(query, ctx);
    },
  });
}
