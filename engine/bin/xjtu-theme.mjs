#!/usr/bin/env node
import { disableTheme, enableTheme, environmentReport, previewTheme, switchTheme, verifyTheme } from "../src/runtime.mjs";

const [command, ...rawArgs] = process.argv.slice(2);
const dryRun = rawArgs.includes("--dry-run");
const args = rawArgs.filter((value) => value !== "--dry-run");

function mode(value, fallback) {
  const selected = value || fallback;
  if (selected !== "dark" && selected !== "light") throw new Error("Theme must be 'dark' or 'light'.");
  return selected;
}

async function main() {
  let result;
  switch (command) {
    case "doctor":
    case "status":
      result = await environmentReport();
      break;
    case "verify":
      result = await verifyTheme();
      if (!result.healthy) process.exitCode = 1;
      break;
    case "preview":
      result = await previewTheme(mode(args[0], "dark"), { dryRun });
      break;
    case "switch": {
      const target = args[0] || "toggle";
      if (!["toggle", "dark", "light"].includes(target)) throw new Error("Switch target must be toggle, dark, or light.");
      result = await switchTheme(target, { dryRun });
      break;
    }
    case "enable":
      result = await enableTheme(mode(args[0], "dark"), { dryRun });
      break;
    case "disable":
    case "restore":
      result = await disableTheme({ dryRun });
      break;
    default:
      console.log("Usage: xjtu-theme <doctor|status|verify|preview|switch|enable|disable|restore> [dark|light|toggle] [--dry-run]");
      process.exitCode = command ? 2 : 0;
      return;
  }
  console.log(JSON.stringify(result, null, 2));
}

main().catch((error) => {
  console.error(`xjtu-theme: ${error.message}`);
  process.exitCode = 1;
});
