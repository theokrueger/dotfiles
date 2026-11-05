/**
 * `/retry` — continue the session after an abort.
 *
 *   /retry   re-issue the model request without adding anything to the conversation
 *
 * Escape aborts a run but leaves the partial response in context. /retry starts a
 * new run with a hidden trigger message (the only way the extension API can start
 * a run), but a `context` handler strips every retry trigger out of the transcript
 * before the model request, so the LLM sees exactly the same message list as the
 * previous attempt — no nudge, no duplicate entries, just a plain retry.
 */

import type { AgentMessage, ExtensionAPI } from "@earendil-works/pi-coding-agent";

const CUSTOM_TYPE = "retry-continue";

const TRIGGER = "/retry";

function isRetryTrigger(message: AgentMessage): boolean {
  return message.role === "custom" && (message as { customType?: string }).customType === CUSTOM_TYPE;
}

export default function (pi: ExtensionAPI) {
  // Hide the trigger from the LLM: the retried request carries the same
  // conversation as before, with the partial assistant response still last.
  pi.on("context", (event) => ({
    messages: event.messages.filter((m) => !isRetryTrigger(m)),
  }));

  pi.registerCommand("retry", {
    description: "Retry the last model request without adding messages",
    handler: async (_args, ctx) => {
      if (!ctx.isIdle()) {
        ctx.ui.notify("Still running: /retry only continues an idle session.", "warning");
        return;
      }
      pi.sendMessage(
        { customType: CUSTOM_TYPE, content: TRIGGER, display: false },
        { triggerTurn: true },
      );
    },
  });
}
