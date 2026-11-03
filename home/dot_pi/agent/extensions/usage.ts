/**
 * `/usage` — token and cost totals across all saved sessions.
 *
 *   /usage   last 24h, 7d, and 30d totals plus the top models over 30d
 *
 * Counts assistant messages, `usage` entries, and compaction/branch summaries.
 * Forking or cloning copies history into a new file, so records are
 * deduplicated by entry id before summing.
 */

import { readdir, readFile } from "node:fs/promises";
import { join } from "node:path";
import { getAgentDir, parseSessionEntries } from "@earendil-works/pi-coding-agent";
import type { ExtensionAPI, SessionEntry } from "@earendil-works/pi-coding-agent";
import type { Usage } from "@earendil-works/pi-ai";
import { Box, Text } from "@earendil-works/pi-tui";

const ENTRY_TYPE = "usage-report";
const DAY = 24 * 60 * 60 * 1000;
const WINDOWS = [["24h", 1], ["7d", 7], ["30d", 30]] as const;
const TOP_MODELS = 5;

interface Total {
  tokens: number;
  cost: number;
}

interface UsageRecord extends Total {
  at: number;
  model: string;
}

interface Report {
  generatedAt: number;
  windows: ({ key: string } & Total)[];
  models: ({ model: string } & Total)[];
}

type Style = (text: string) => string;

const record = (at: number, model: string, usage: Usage): UsageRecord => ({
  at,
  model,
  tokens: usage.totalTokens ?? usage.input + usage.output + usage.cacheRead + usage.cacheWrite,
  cost: usage.cost?.total ?? 0,
});

/** The usage record carried by a session entry, if it has one. */
function recordOf(entry: SessionEntry, at: number): UsageRecord | undefined {
  if (entry.type === "message") {
    const { message } = entry;
    if (message.role !== "assistant") return;
    return record(at, `${message.provider}/${message.model}`, message.usage);
  }
  if (entry.type === "usage") return record(at, `${entry.provider}/${entry.model}`, entry.usage);
  if ((entry.type === "compaction" || entry.type === "branch_summary") && entry.usage) {
    return record(at, "compaction/summary", entry.usage);
  }
}

async function collect(): Promise<UsageRecord[]> {
  const since = Date.now() - 30 * DAY;
  const dir = join(getAgentDir(), "sessions");
  const byId = new Map<string, UsageRecord>();

  for (const name of await readdir(dir, { recursive: true }).catch(() => [])) {
    if (!name.endsWith(".jsonl")) continue;

    const text = await readFile(join(dir, name), "utf8").catch(() => "");
    for (const entry of parseSessionEntries(text)) {
      const at = Date.parse(entry.timestamp);
      if (!(at >= since)) continue;

      // Forks keep entry ids, so the same record never counts twice.
      const r = recordOf(entry, at);
      if (r) byId.set(entry.id, r);
    }
  }

  return [...byId.values()];
}

const num = (n: number) => Math.round(n).toLocaleString("en-US");
const money = (n: number) => `$${n.toFixed(4)}`;

function report(records: UsageRecord[]): Report {
  const now = Date.now();
  const total = (rs: UsageRecord[]): Total => ({
    tokens: rs.reduce((n, r) => n + r.tokens, 0),
    cost: rs.reduce((n, r) => n + r.cost, 0),
  });

  const byModel = new Map<string, Total>();
  for (const { model, tokens, cost } of records) {
    const m = byModel.get(model) ?? { tokens: 0, cost: 0 };
    byModel.set(model, { tokens: m.tokens + tokens, cost: m.cost + cost });
  }

  return {
    generatedAt: now,
    windows: WINDOWS.map(([key, days]) => ({
      key,
      ...total(records.filter((r) => r.at >= now - days * DAY)),
    })),
    models: [...byModel]
      .sort((a, b) => b[1].tokens - a[1].tokens)
      .slice(0, TOP_MODELS)
      .map(([model, t]) => ({ model, ...t })),
  };
}

function render(r: Report, dim: Style = (t) => t, bold: Style = (t) => t): string {
  const since = new Date(r.generatedAt - 30 * DAY).toLocaleDateString("sv-SE");
  const tokensW = Math.max(6, ...r.windows.map((w) => num(w.tokens).length));
  const costW = Math.max(4, ...r.windows.map((w) => money(w.cost).length));
  const labelW = Math.max(4, ...r.models.map((m) => m.model.length));
  const row = (label: string, tokens: number, cost: number) =>
    `${label.padEnd(4)}${dim(num(tokens).padStart(tokensW + 2))}${dim(
      money(cost).padStart(costW + 2),
    )}`;

  return [
    `${bold("Usage")} ${dim(`since ${since}`)}`,
    ...r.windows.map((w) => row(w.key, w.tokens, w.cost)),
    "",
    bold("Top models"),
    ...r.models.map((m) => row(m.model.padEnd(labelW), m.tokens, m.cost)),
  ].join("\n");
}

export default function (pi: ExtensionAPI) {
  pi.registerEntryRenderer<Report>(ENTRY_TYPE, (entry, _options, theme) => {
    if (!entry.data) return undefined;
    const text = render(
      entry.data,
      (value) => theme.fg("dim", value),
      (value) => theme.bold(value),
    );
    const box = new Box(1, 1, (value) => theme.bg("customMessageBg", value));
    box.addChild(new Text(text, 0, 0));
    return box;
  });

  pi.registerCommand("usage", {
    description: "Show token and cost totals for the last 24h, 7d, and 30d",
    handler: async (_args, ctx) => {
      const records = await collect();
      if (!records.length) {
        ctx.ui.notify("No model usage recorded in the last 30 days.", "info");
        return;
      }

      const data = report(records);
      if (ctx.mode === "tui") pi.appendEntry<Report>(ENTRY_TYPE, data);
      else ctx.ui.notify(render(data), "info");
    },
  });
}
