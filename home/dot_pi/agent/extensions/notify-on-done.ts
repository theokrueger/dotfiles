/**
 * Desktop notification when the agent yields control back to you.
 *
 * Uses `notify-send` (libnotify) on `agent_settled`, which fires only after
 * retries, compaction, and queued continuations are finished.
 */

import { execFile } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const APP_NAME = "pi";

/** Fire-and-forget: failures (no notification daemon, etc.) are ignored. */
const notify = (title: string, body: string) => {
  execFile("notify-send", [`--app-name=${APP_NAME}`, title, body], () => {});
};

export default function (pi: ExtensionAPI) {
  pi.on("agent_settled", (event, ctx) => {
    notify(
      event.aborted ? "Aborted" : "Finished",
      `${ctx.model?.name ?? "Unknown Model"}\n${ctx.cwd}`,
    );
  });
}
