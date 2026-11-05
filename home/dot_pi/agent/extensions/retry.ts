/**
 * `/retry` — continue the session after an abort.
 *
 *   /retry   ask the model to pick up where the aborted run stopped
 *
 * Escape aborts a run but leaves the partial response in context; the model
 * will not resume on its own until asked. The nudge is a hidden custom message,
 * so no fake user turn appears in the transcript.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const CUSTOM_TYPE = "retry-continue";

const NUDGE = "The previous run was interrupted. Continue from where it stopped.";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("retry", {
    description: "Continue the session after an aborted run",
    handler: async (_args, ctx) => {
      if (!ctx.isIdle()) {
        ctx.ui.notify("Still running: /retry only continues an idle session.", "warning");
        return;
      }
      pi.sendMessage(
        { customType: CUSTOM_TYPE, content: NUDGE, display: false },
        { triggerTurn: true },
      );
    },
  });
}
