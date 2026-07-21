import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

function powershell(command) {
  return execFileSync("powershell.exe", ["-NoProfile", "-Command", command], { encoding: "utf8" }).trim();
}

function hostOverride() {
  try {
    const value = JSON.parse(process.env.XJTU_THEME_HOST_INFO || "");
    if (!value?.executable || value.signatureKind !== "Store" || !fs.existsSync(value.executable)) return null;
    return {
      Location: value.location || path.dirname(value.executable),
      SignatureKind: value.signatureKind,
      Version: value.version || "unknown",
      executable: value.executable,
      pid: Number(value.pid) || null,
    };
  } catch {
    return null;
  }
}

export function findCodexBundle() {
  const override = hostOverride();
  if (override) return override;
  const command = "$p=Get-AppxPackage OpenAI.Codex|Sort-Object Version -Descending|Select-Object -First 1;if($p){[pscustomobject]@{Location=$p.InstallLocation;SignatureKind=[string]$p.SignatureKind;Version=[string]$p.Version}|ConvertTo-Json -Compress}";
  let output;
  try { output = powershell(command); } catch { output = ""; }
  if (!output) throw new Error("Microsoft Store Codex package OpenAI.Codex was not found.");
  const info = JSON.parse(output);
  const candidates = [path.join(info.Location, "ChatGPT.exe"), path.join(info.Location, "app", "ChatGPT.exe")];
  const executable = candidates.find((candidate) => fs.existsSync(candidate));
  if (!executable) throw new Error(`ChatGPT.exe was not found under ${info.Location}`);
  return { ...info, executable };
}

export function verifyCodexBundle(bundle) {
  return bundle?.SignatureKind === "Store" && fs.existsSync(bundle.executable);
}

export function pickWindowsMainPid(json) {
  let processes;
  try { processes = JSON.parse(json); } catch { return null; }
  if (!Array.isArray(processes)) processes = processes ? [processes] : [];
  for (const processInfo of processes) {
    const commandLine = String(processInfo.CommandLine || "");
    if (!commandLine) continue;
    // Electron's Crashpad handler does not use --type=, but is not the Node main process.
    if (/(?:^|\s)--type=|crashpad-handler/i.test(commandLine)) continue;
    return Number(processInfo.ProcessId);
  }
  return null;
}

export function findCodexMainPid() {
  const override = hostOverride();
  if (override?.pid) return override.pid;
  const command = "Get-CimInstance Win32_Process -Filter \"Name='ChatGPT.exe'\"|Select-Object ProcessId,CommandLine|ConvertTo-Json -Compress";
  try { return pickWindowsMainPid(powershell(command)); } catch { return null; }
}
