import fs from "node:fs";
import path from "node:path";
import { stateRoot } from "./config.mjs";

function lockPath() {
  return path.join(stateRoot(), "operation.lock");
}

export async function withOperationLock(callback) {
  fs.mkdirSync(stateRoot(), { recursive: true });
  const filename = lockPath();
  let handle;
  try {
    try {
      handle = fs.openSync(filename, "wx");
    } catch (error) {
      if (error.code !== "EEXIST") throw error;
      const stat = fs.statSync(filename);
      if (Date.now() - stat.mtimeMs <= 120000) {
        const busy = new Error("Another XJTU theme operation is already running.");
        busy.code = "XJTU_THEME_BUSY";
        throw busy;
      }
      fs.rmSync(filename, { force: true });
      handle = fs.openSync(filename, "wx");
    }
    fs.writeFileSync(handle, JSON.stringify({ pid: process.pid, createdAt: new Date().toISOString() }));
    return await callback();
  } finally {
    if (handle !== undefined) {
      try { fs.closeSync(handle); } catch { /* already closed */ }
      try { fs.rmSync(filename, { force: true }); } catch { /* already removed */ }
    }
  }
}
