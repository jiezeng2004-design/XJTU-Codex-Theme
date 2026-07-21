import { setTimeout as sleep } from "node:timers/promises";
import { findCodexMainPid } from "./codex.mjs";
import { appendAgentLog, readState } from "./state.mjs";
import { previewTheme } from "./runtime.mjs";

async function tick() {
  const state = readState();
  if (!state?.enabled || !["dark", "light"].includes(state.mode)) return;
  const pid = findCodexMainPid();
  if (!pid || state.appliedPid === pid) return;
  try {
    await previewTheme(state.mode);
    const next = readState();
    if (next) {
      const { writeState } = await import("./state.mjs");
      writeState({ ...next, enabled: true, source: "agent" });
    }
    appendAgentLog(`Applied ${state.mode} to Codex PID ${pid}.`);
  } catch (error) {
    if (error.code !== "XJTU_THEME_BUSY") appendAgentLog(`Apply failed: ${error.message}`);
  }
}

appendAgentLog("Agent started.");
for (;;) {
  await tick();
  await sleep(3500);
}
