import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const testStateRoot = fs.mkdtempSync(path.join(os.tmpdir(), "xjtu-theme-engine-test-"));
process.env.XJTU_THEME_STATE_DIR = testStateRoot;

const { loadTheme, PROJECT_ROOT } = await import("../src/config.mjs");
const { environmentReport } = await import("../src/runtime.mjs");
const { pickWindowsMainPid } = await import("../src/codex.mjs");
const { FIXED_CSS, buildApplyExpression, buildRendererScript, RESTORE_EXPRESSION, VERIFY_EXPRESSION } = await import("../src/inject.mjs");
const { withOperationLock } = await import("../src/lock.mjs");
const { clearState, readState, resolveTarget, writeState } = await import("../src/state.mjs");

test.after(() => {
  fs.rmSync(testStateRoot, { recursive: true, force: true });
});

test("loads both local themes and keeps images inside the project", () => {
  for (const mode of ["dark", "light"]) {
    const theme = loadTheme(mode);
    assert.equal(theme.mode, mode);
    assert.ok(fs.existsSync(theme.imagePath));
    assert.equal(path.relative(PROJECT_ROOT, theme.imagePath).startsWith(".."), false);
    assert.equal(theme.layout.zoom, "116%");
  }
});

test("environment report keeps recovery available when a theme is unavailable", async () => {
  const report = await environmentReport();
  assert.ok(report.themes.dark?.id || report.themes.dark?.available === false);
  assert.ok(report.themes.light?.id || report.themes.light?.available === false);
});

test("wallpaper CSS uses one fixed body layer without renderer observers", () => {
  assert.match(FIXED_CSS, /html\.xjtu-hot-theme body/);
  assert.match(FIXED_CSS, /main\.main-surface/);
  assert.match(FIXED_CSS, /aside\.app-shell-left-panel/);
  assert.match(FIXED_CSS, /\[role="menu"\]/);
  assert.match(FIXED_CSS, /\[role="menuitem"\]/);
  assert.equal((FIXED_CSS.match(/background-attachment: fixed/g) || []).length, 1);
  assert.doesNotMatch(FIXED_CSS, /backdrop-filter:\s*blur/);
  assert.doesNotMatch(FIXED_CSS, /main\.main-surface:has\(/);
});

test("renderer payload is local, skips utility windows, and supports cleanup", () => {
  const theme = loadTheme("dark");
  const renderer = buildRendererScript(theme);
  assert.match(renderer, /avatar-overlay/);
  assert.match(renderer, /URL\.createObjectURL/);
  assert.match(renderer, /URL\.revokeObjectURL/);
  assert.ok(renderer.includes(theme.id), "renderer payload must include the active theme id");
  assert.doesNotMatch(renderer, /https?:\/\//);
  assert.doesNotMatch(renderer, /MutationObserver/);
  assert.doesNotMatch(renderer, /setInterval\(ensure/);
  const apply = buildApplyExpression(renderer);
  assert.match(apply, /browser-window-created/);
  assert.match(apply, /dom-ready/);
  assert.match(RESTORE_EXPRESSION, /removeListener/);
  assert.match(VERIFY_EXPRESSION, /requestAnimationFrame/);
  assert.match(VERIFY_EXPRESSION, /bodyPointerEvents/);
});

test("resolves explicit and toggle targets", () => {
  assert.equal(resolveTarget("toggle", null), "dark");
  assert.equal(resolveTarget("toggle", "dark"), "light");
  assert.equal(resolveTarget("toggle", "light"), "dark");
  assert.equal(resolveTarget("dark", "light"), "dark");
  assert.throws(() => resolveTarget("unknown", null));
});

test("selects only the Windows main process", () => {
  const json = JSON.stringify([
    { ProcessId: 5, CommandLine: "ChatGPT.exe --monitor-self-annotation=ptype=crashpad-handler" },
    { ProcessId: 10, CommandLine: "ChatGPT.exe --type=renderer" },
    { ProcessId: 20, CommandLine: "C:\\Program Files\\WindowsApps\\ChatGPT.exe" },
  ]);
  assert.equal(pickWindowsMainPid(json), 20);
  assert.equal(pickWindowsMainPid("not json"), null);
});

test("writes state atomically and clears it", () => {
  assert.equal(readState(), null);
  const saved = writeState({ enabled: false, mode: "dark", appliedPid: 123 });
  assert.equal(saved.schemaVersion, 1);
  assert.equal(readState().mode, "dark");
  clearState();
  assert.equal(readState(), null);
});

test("operation lock rejects concurrent work", async () => {
  await withOperationLock(async () => {
    await assert.rejects(() => withOperationLock(async () => true), /already running/);
  });
});
