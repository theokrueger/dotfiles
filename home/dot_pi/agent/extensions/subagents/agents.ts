/**
 * Subagent discovery.
 *
 * A subagent is a markdown file with YAML frontmatter. Built-ins live in
 * ./agents; your own live in ~/.pi/agent/agents, where a same-named file
 * replaces a built-in. Everything after the frontmatter is the system prompt.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

import type { ThinkingLevel } from "@earendil-works/pi-agent-core";
import { getAgentDir, parseFrontmatter } from "@earendil-works/pi-coding-agent";

export interface AgentConfig {
  name: string;
  /** Routing text: says when to delegate, not just what the agent is. */
  description: string;
  /** Tool allowlist; undefined means pi's default tool set. */
  tools?: string[];
  /** Model override; undefined inherits the session's model. */
  model?: string;
  /** Thinking override; undefined inherits the session's level. */
  thinking?: ThinkingLevel;
  /** Wall-clock cap in minutes; undefined uses the dispatch default. */
  timeout?: number;
  /** Character cap on the summary returned to the parent. */
  maxOutput?: number;
  systemPrompt: string;
}

// A type alias, not an interface: parseFrontmatter wants a Record, and only an
// alias satisfies it without an explicit index signature.
type Frontmatter = {
  name?: unknown;
  description?: unknown;
  tools?: unknown;
  model?: unknown;
  thinking?: unknown;
  timeout?: unknown;
  maxOutput?: unknown;
};

const BASE = path.dirname(fileURLToPath(import.meta.url));
const BUILTIN_DIR = path.join(BASE, "agents");
const USER_DIR = path.join(getAgentDir(), "agents");
const THINKING = ["off", "minimal", "low", "medium", "high", "xhigh", "max"] as const satisfies readonly ThinkingLevel[];

const text = (value: unknown) =>
  typeof value === "string" ? value.trim() || undefined : undefined;

/** Accept both `tools: read, bash` and `tools: [read, bash]`. */
function toolList(value: unknown): string[] | undefined {
  const raw = Array.isArray(value) ? value : [value];
  const tools = raw
    .flatMap((entry) => (typeof entry === "string" ? entry.split(",") : []))
    .map((entry) => entry.trim())
    .filter(Boolean);
  return tools.length > 0 ? tools : undefined;
}

const thinkingLevel = (value: unknown): ThinkingLevel | undefined =>
  typeof value === "string"
    ? THINKING.find((level) => level === value.trim().toLowerCase())
    : undefined;

/** A positive whole number, or undefined for a missing or invalid value. */
function positive(value: unknown): number | undefined {
  let n: number;
  if (typeof value === "number") n = value;
  else if (typeof value === "string") n = Number(value.trim());
  else return undefined;

  return Number.isFinite(n) && n > 0 ? Math.floor(n) : undefined;
}

function load(dir: string): AgentConfig[] {
  let entries: fs.Dirent[];
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return [];
  }

  const agents: AgentConfig[] = [];
  for (const entry of entries) {
    if (!entry.name.endsWith(".md")) continue;
    if (!entry.isFile() && !entry.isSymbolicLink()) continue;

    try {
      const file = path.join(dir, entry.name);
      const { frontmatter, body } = parseFrontmatter<Frontmatter>(fs.readFileSync(file, "utf8"));
      const name = text(frontmatter.name);
      const description = text(frontmatter.description);
      if (!name || !description) continue;

      agents.push({
        name,
        description,
        tools: toolList(frontmatter.tools),
        model: text(frontmatter.model),
        thinking: thinkingLevel(frontmatter.thinking),
        timeout: positive(frontmatter.timeout),
        maxOutput: positive(frontmatter.maxOutput),
        systemPrompt: body.trim(),
      });
    } catch {
      // One unreadable file must not hide every other agent.
    }
  }

  return agents;
}

/** Read on demand, so a new agent file needs no reload. */
export function discoverAgents(): AgentConfig[] {
  const byName = new Map<string, AgentConfig>();
  for (const agent of [...load(BUILTIN_DIR), ...load(USER_DIR)]) {
    byName.set(agent.name, agent);
  }
  return [...byName.values()];
}

/** One line per agent, for the tool description. */
export function formatCatalog(agents: AgentConfig[]): string {
  return agents.map((agent) => `- ${agent.name}: ${agent.description}`).join("\n");
}
