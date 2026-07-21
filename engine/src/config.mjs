import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const ENGINE_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
export const PROJECT_ROOT = path.resolve(ENGINE_ROOT, "..");
export const ENGINE_VERSION = "0.2.1";
export const TASK_NAME = "XJTU-Codex-Theme";
export const INSPECTOR_PORT = 9229;

export function stateRoot() {
  return process.env.XJTU_THEME_STATE_DIR
    ? path.resolve(process.env.XJTU_THEME_STATE_DIR)
    : path.join(process.env.LOCALAPPDATA || path.join(os.homedir(), "AppData", "Local"), "XJTU-Codex-Theme");
}

export function statePath() {
  return path.join(stateRoot(), "state.json");
}

export function logPath() {
  return path.join(stateRoot(), "agent.log");
}

export function themePath(mode) {
  if (mode !== "dark" && mode !== "light") throw new Error(`Unsupported theme mode: ${mode}`);
  return path.join(ENGINE_ROOT, "themes", `${mode}.json`);
}

const COLOR = /^(#[0-9a-f]{6}|rgba?\([^\r\n;{}]+\))$/i;
const PERCENT = /^(?:100|[0-9]{1,2}|1[01][0-9]|120)%$/;
const COLOR_KEYS = ["background", "panel", "accent", "text", "muted", "line"];
const LAYOUT_KEYS = [
  "positionX", "zoom", "bodyScrimStart", "bodyScrimEnd", "mainScrimStart",
  "mainScrimEnd", "sidebarScrimStart", "sidebarScrimEnd", "conversationWallpaper",
];

export function loadTheme(mode) {
  const filename = themePath(mode);
  const value = JSON.parse(fs.readFileSync(filename, "utf8"));
  const allowed = new Set(["schemaVersion", "id", "name", "variant", "image", "colors", "layout"]);
  for (const key of Object.keys(value)) if (!allowed.has(key)) throw new Error(`Unknown theme field: ${key}`);
  if (value.schemaVersion !== 1) throw new Error("Theme schemaVersion must be 1.");
  if (value.variant !== mode) throw new Error(`Theme variant must be '${mode}'.`);
  if (!/^[a-z0-9][a-z0-9-]{0,63}$/.test(value.id || "")) throw new Error("Theme id is invalid.");
  if (typeof value.name !== "string" || !value.name.trim()) throw new Error("Theme name is invalid.");
  if (!value.colors || typeof value.colors !== "object") throw new Error("Theme colors are missing.");
  for (const key of COLOR_KEYS) if (!COLOR.test(value.colors[key] || "")) throw new Error(`Theme color '${key}' is invalid.`);
  for (const key of Object.keys(value.colors)) if (!COLOR_KEYS.includes(key)) throw new Error(`Unknown theme color: ${key}`);
  if (!value.layout || typeof value.layout !== "object") throw new Error("Theme layout is missing.");
  for (const key of Object.keys(value.layout)) if (!LAYOUT_KEYS.includes(key)) throw new Error(`Unknown layout field: ${key}`);
  for (const key of LAYOUT_KEYS.filter((item) => item !== "conversationWallpaper")) {
    if (!PERCENT.test(value.layout[key] || "")) throw new Error(`Theme layout '${key}' is invalid.`);
  }
  if (typeof value.layout.conversationWallpaper !== "boolean") throw new Error("conversationWallpaper must be boolean.");

  const imagePath = path.resolve(path.dirname(filename), value.image);
  const relative = path.relative(PROJECT_ROOT, imagePath);
  if (relative.startsWith("..") || path.isAbsolute(relative)) throw new Error("Theme image must stay inside the project.");
  if (!fs.existsSync(imagePath) || !fs.statSync(imagePath).isFile()) throw new Error(`Theme image not found: ${imagePath}`);
  return { ...value, mode, filename, imagePath };
}

export function codeDrobeState() {
  const root = path.join(process.env.LOCALAPPDATA || "", "CodeDrobe");
  return {
    activeSnapshot: path.join(root, "backups", "xjtu-codex-theme", "active.json"),
    hostBackup: path.join(root, "config.before-codedrobe.toml"),
  };
}
