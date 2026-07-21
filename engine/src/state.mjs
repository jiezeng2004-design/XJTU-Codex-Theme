import fs from "node:fs";
import path from "node:path";
import { ENGINE_VERSION, statePath, stateRoot } from "./config.mjs";

export function readState() {
  try {
    const value = JSON.parse(fs.readFileSync(statePath(), "utf8"));
    return value?.schemaVersion === 1 ? value : null;
  } catch {
    return null;
  }
}

export function writeState(value) {
  fs.mkdirSync(stateRoot(), { recursive: true });
  const target = statePath();
  const temporary = `${target}.${process.pid}.tmp`;
  const next = { schemaVersion: 1, engineVersion: ENGINE_VERSION, ...value };
  fs.writeFileSync(temporary, `${JSON.stringify(next, null, 2)}\n`, "utf8");
  fs.renameSync(temporary, target);
  return next;
}

export function clearState() {
  try { fs.rmSync(statePath(), { force: true }); } catch { /* already absent */ }
}

export function appendAgentLog(message) {
  fs.mkdirSync(stateRoot(), { recursive: true });
  fs.appendFileSync(path.join(stateRoot(), "agent.log"), `${new Date().toISOString()} ${message}\n`, "utf8");
}

export function resolveTarget(requested, currentMode = null) {
  if (requested === "dark" || requested === "light") return requested;
  if (requested !== "toggle") throw new Error(`Unsupported target: ${requested}`);
  if (currentMode === "dark") return "light";
  if (currentMode === "light") return "dark";
  return "dark";
}
