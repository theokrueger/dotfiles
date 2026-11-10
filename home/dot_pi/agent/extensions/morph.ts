/**
 * Model provider: Morph (https://morphllm.com), an OpenAI-compatible endpoint.
 *
 *   /login morph   store a Morph API key, or export MORPH_API_KEY
 *   /model         Kimi K3, Kimi K3.1 Pro, DeepSeek V4.1 Flash
 *
 * The catalog is local, so startup never waits on the network. Costs are USD per
 * million tokens, copied from morphllm.com/api/models/json?prices=list.
 */

import type { ModelCost, ModelThinkingLevel, ThinkingLevelMap } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ProviderModelConfig } from "@earendil-works/pi-coding-agent";

const PROVIDER_ID = "morph";
const BASE_URL = "https://api.morphllm.com/v1";
const CONTEXT_WINDOW = 1_048_576;
const MAX_TOKENS = 131_072; // pi's catalogs stop near here even at 1M context

/** Morph takes `max_tokens` and `system` only, and accepts extended effort values. */
const COMPAT = {
  maxTokensField: "max_tokens",
  supportsDeveloperRole: false,
  supportsStore: false,
  supportsReasoningEffort: true,
  supportsFinishReason: true,
} as const;

const COST = {
  kimi: { input: 2.5, output: 14, cacheRead: 0.29, cacheWrite: 0 },
  deepseek: { input: 0.12, output: 0.8, cacheRead: 0.008, cacheWrite: 0 },
};

// All levels explicit (docs.morphllm.com/llms.txt): pi would pass `minimal`,
// `xhigh` and `max` through verbatim, and Morph 400s on unsupported values.
// Kimi K3 has no `minimal` tier.
const EFFORT = {
  kimi: { off: "none", minimal: "low", low: "low", medium: "medium", high: "high", xhigh: "xhigh", max: "max" },
  deepseek: { off: "none", minimal: "minimal", low: "low", medium: "medium", high: "high", xhigh: "xhigh", max: "max" },
} satisfies Record<string, Record<ModelThinkingLevel, string>>;

const model = (
  id: string,
  name: string,
  cost: ModelCost,
  thinkingLevelMap: ThinkingLevelMap,
): ProviderModelConfig => ({
  id,
  name,
  reasoning: true,
  input: ["text", "image"],
  cost,
  contextWindow: CONTEXT_WINDOW,
  maxTokens: MAX_TOKENS,
  thinkingLevelMap,
  compat: COMPAT,
});

const MODELS = [
  model("morph-kimik3", "Kimi K3", COST.kimi, EFFORT.kimi),
  model("morph-kimik31", "Kimi K3.1 Pro", COST.kimi, EFFORT.kimi),
  model("morph-dsv41flash", "DeepSeek V4.1 Flash", COST.deepseek, EFFORT.deepseek),
  model("morph-dsv41flash-1017", "DeepSeek V4.1 Flash 1017", COST.deepseek, EFFORT.deepseek),
];

export default function (pi: ExtensionAPI) {
  pi.registerProvider(PROVIDER_ID, {
    name: "Morph",
    baseUrl: BASE_URL,
    api: "openai-completions",
    apiKey: "$MORPH_API_KEY",
    models: MODELS,
  });
}
