import fs from "node:fs";
import net from "node:net";
import { codeDrobeState, ENGINE_VERSION, INSPECTOR_PORT, loadTheme, statePath } from "./config.mjs";
import { findCodexBundle, findCodexMainPid, verifyCodexBundle } from "./codex.mjs";
import { buildApplyExpression, buildRendererScript, RESTORE_EXPRESSION, VERIFY_EXPRESSION } from "./inject.mjs";
import { withOperationLock } from "./lock.mjs";
import { installAgent, taskExists, uninstallAgent } from "./persist.mjs";
import { inspectorPortOpen, pulse } from "./pulse.mjs";
import { clearState, readState, resolveTarget, writeState } from "./state.mjs";

function portListening(port, timeoutMs = 250) {
  return new Promise((resolve) => {
    const socket = net.createConnection({ host: "127.0.0.1", port });
    const finish = (value) => { socket.destroy(); resolve(value); };
    socket.setTimeout(timeoutMs);
    socket.once("connect", () => finish(true));
    socket.once("timeout", () => finish(false));
    socket.once("error", () => finish(false));
  });
}

export async function environmentReport() {
  let bundle = null;
  let bundleError = null;
  try { bundle = findCodexBundle(); } catch (error) { bundleError = error.message; }
  const codeDrobe = codeDrobeState();
  return {
    engineVersion: ENGINE_VERSION,
    nodeVersion: process.version,
    platform: process.platform,
    codex: bundle ? {
      installed: true,
      version: bundle.Version,
      executable: bundle.executable,
      storeSignature: verifyCodexBundle(bundle),
      runningPid: findCodexMainPid(),
    } : { installed: false, error: bundleError, runningPid: findCodexMainPid() },
    ports: { inspector9229: await inspectorPortOpen(), codeDrobe9335: await portListening(9335) },
    conflicts: {
      codeDrobeSnapshot: fs.existsSync(codeDrobe.activeSnapshot),
      codeDrobeBackup: fs.existsSync(codeDrobe.hostBackup),
    },
    state: readState(),
    statePath: statePath(),
    scheduledTask: taskExists(),
    themes: {
      dark: summarizeTheme(loadTheme("dark")),
      light: summarizeTheme(loadTheme("light")),
    },
  };
}

function summarizeTheme(theme) {
  return { id: theme.id, name: theme.name, mode: theme.mode, imagePath: theme.imagePath, layout: theme.layout };
}

function assertBundle(bundle) {
  if (!verifyCodexBundle(bundle)) throw new Error("Codex Store signature validation failed. Refusing to inject.");
}

async function assertNoCodeDrobeConflict() {
  const paths = codeDrobeState();
  const conflicts = [];
  if (fs.existsSync(paths.activeSnapshot)) conflicts.push(paths.activeSnapshot);
  if (fs.existsSync(paths.hostBackup)) conflicts.push(paths.hostBackup);
  if (await portListening(9335)) conflicts.push("127.0.0.1:9335");
  if (conflicts.length) {
    throw new Error(`CodeDrobe state is still active (${conflicts.join(", ")}). Restore it before using the hot theme engine.`);
  }
}

async function assertInspectorClosed() {
  for (let attempt = 0; attempt < 10; attempt += 1) {
    if (!(await inspectorPortOpen())) return;
    await new Promise((resolve) => setTimeout(resolve, 120));
  }
  throw new Error(`Inspector port ${INSPECTOR_PORT} remained open after the pulse.`);
}

function applyPlan(mode, theme, report) {
  return {
    action: "apply",
    mode,
    theme: summarizeTheme(theme),
    codexRunning: Boolean(report.codex.runningPid),
    codexPid: report.codex.runningPid || null,
    opensInspectorBriefly: true,
    inspectorPort: INSPECTOR_PORT,
    restartsCodex: false,
    modifiesCodexFiles: false,
  };
}

async function applyUnlocked(mode, { enabled = false, dryRun = false, source = "preview" } = {}) {
  const theme = loadTheme(mode);
  const report = await environmentReport();
  const plan = applyPlan(mode, theme, report);
  if (dryRun) return { ...plan, dryRun: true };
  if (!report.codex.installed) throw new Error(report.codex.error || "Codex is not installed.");
  const bundle = findCodexBundle();
  assertBundle(bundle);

  await assertNoCodeDrobeConflict();
  if (!report.codex.runningPid) throw new Error("Codex is not running. Open Codex normally, then retry.");
  const rendererScript = buildRendererScript(theme);
  const results = await pulse(buildApplyExpression(rendererScript));
  await assertInspectorClosed();
  if (!Array.isArray(results) || !results.some((result) => result?.installed)) {
    throw new Error(`No compatible Codex renderer accepted the theme: ${JSON.stringify(results)}`);
  }
  const state = writeState({
    enabled,
    mode,
    themeId: theme.id,
    appliedPid: findCodexMainPid(),
    appliedAt: new Date().toISOString(),
    source,
  });
  return { ...plan, state, results };
}

export async function previewTheme(mode, options = {}) {
  if (options.dryRun) return applyUnlocked(mode, { enabled: false, dryRun: true, source: "preview" });
  return withOperationLock(() => applyUnlocked(mode, { enabled: false, source: "preview" }));
}

export async function switchTheme(requested = "toggle", options = {}) {
  const current = readState();
  const mode = resolveTarget(requested, current?.mode || null);
  if (current?.mode === mode && current?.appliedPid === findCodexMainPid()) {
    return { action: "switch", changed: false, mode, reason: "already-active", dryRun: Boolean(options.dryRun) };
  }
  if (options.dryRun) {
    const plan = await applyUnlocked(mode, { enabled: Boolean(current?.enabled), dryRun: true, source: "switch" });
    return { ...plan, action: "switch", from: current?.mode || null, to: mode };
  }
  return withOperationLock(async () => {
    const result = await applyUnlocked(mode, { enabled: Boolean(current?.enabled), source: "switch" });
    return { ...result, action: "switch", from: current?.mode || null, to: mode, changed: true };
  });
}

export async function enableTheme(mode, options = {}) {
  const theme = loadTheme(mode);
  const report = await environmentReport();
  if (options.dryRun) {
    return {
      action: "enable",
      dryRun: true,
      mode,
      theme: summarizeTheme(theme),
      codexRunning: Boolean(report.codex.runningPid),
      createsScheduledTask: true,
      taskName: "XJTU-Codex-Theme",
      restartsCodex: false,
    };
  }
  if (!report.codex.installed) throw new Error(report.codex.error || "Codex is not installed.");
  assertBundle(findCodexBundle());

  return withOperationLock(async () => {
    await assertNoCodeDrobeConflict();
    let applyResult = null;
    if (findCodexMainPid()) applyResult = await applyUnlocked(mode, { enabled: false, source: "enable" });
    try {
      installAgent();
      const previous = readState() || {};
      const state = writeState({
        ...previous,
        enabled: true,
        mode,
        themeId: theme.id,
        appliedPid: findCodexMainPid() || null,
        enabledAt: new Date().toISOString(),
        source: "enable",
      });
      return { action: "enable", mode, state, applyResult, scheduledTask: taskExists() };
    } catch (error) {
      const previous = readState();
      if (previous) writeState({ ...previous, enabled: false, source: "enable-task-failed" });
      throw error;
    }
  });
}

export async function disableTheme(options = {}) {
  const report = await environmentReport();
  if (options.dryRun) {
    return {
      action: "disable",
      dryRun: true,
      hadState: Boolean(report.state),
      removesScheduledTask: report.scheduledTask,
      restoresRunningCodex: Boolean(report.codex.runningPid),
      restartsCodex: false,
    };
  }

  return withOperationLock(async () => {
    uninstallAgent();
    const pid = findCodexMainPid();
    let restoreResult = null;
    if (pid) {
      try {
        restoreResult = await pulse(RESTORE_EXPRESSION, { allowExisting: true });
        await assertInspectorClosed();
      } catch (error) {
        const previous = readState() || {};
        writeState({ ...previous, enabled: false, appliedPid: null, source: "disable-restore-failed", error: error.message });
        throw error;
      }
    }
    clearState();
    return { action: "disable", restoredPid: pid, restoreResult, scheduledTask: taskExists(), stateCleared: !fs.existsSync(statePath()) };
  });
}

export async function verifyTheme() {
  return withOperationLock(async () => {
    const pid = findCodexMainPid();
    if (!pid) throw new Error("Codex is not running. Open Codex normally, then retry.");
    const results = await pulse(VERIFY_EXPRESSION);
    await assertInspectorClosed();
    const compatible = results.filter((result) => !result?.skipped);
    const healthy = compatible.length > 0 && compatible.every((result) =>
      !result.error && result.renderer?.installed && result.renderer?.stylePresent &&
      result.renderer?.hasMain && result.renderer?.bodyBackgroundPresent &&
      result.renderer?.bodyPointerEvents !== "none" && result.renderer?.mainPointerEvents !== "none"
    );
    return { action: "verify", pid, healthy, results };
  });
}
