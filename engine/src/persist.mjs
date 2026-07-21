import { execFileSync } from "node:child_process";
import path from "node:path";
import { ENGINE_ROOT, TASK_NAME } from "./config.mjs";

export function agentPath() {
  return path.join(ENGINE_ROOT, "src", "agent.mjs");
}

export function taskExists() {
  try {
    execFileSync("schtasks.exe", ["/Query", "/TN", TASK_NAME], { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

export function installAgent() {
  const action = `"${process.execPath}" "${agentPath()}"`;
  execFileSync("schtasks.exe", [
    "/Create", "/TN", TASK_NAME, "/SC", "ONLOGON", "/RL", "LIMITED", "/F", "/TR", action,
  ], { stdio: "ignore" });
  try { execFileSync("schtasks.exe", ["/Run", "/TN", TASK_NAME], { stdio: "ignore" }); }
  catch { /* it will start on the next login */ }
}

export function uninstallAgent() {
  try { execFileSync("schtasks.exe", ["/End", "/TN", TASK_NAME], { stdio: "ignore" }); }
  catch { /* task may not be running */ }
  try { execFileSync("schtasks.exe", ["/Delete", "/TN", TASK_NAME, "/F"], { stdio: "ignore" }); }
  catch { /* task may not exist */ }
}
