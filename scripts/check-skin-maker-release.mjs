import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const officialRepository = "https://github.com/jiezeng2004-design/XJTU-Codex-Theme.git";
const expectedTag = "v0.3.0-rc.3";
const requiredPinnedFiles = [
  "skills/codex-skin-maker/SKILL.md",
  "skills/codex-skin-maker/scripts/check-environment.ps1",
  "engine/src/runtime.mjs",
  "engine/tests/engine.test.mjs",
  "scripts/check-theme-assets.mjs",
  "scripts/test-skin-maker-safety.ps1",
];

function read(relative) {
  return fs.readFileSync(path.join(projectRoot, relative), "utf8");
}

function extract(script, name) {
  const match = script.match(new RegExp(`\\$${name}\\s*=\\s*"([^"]+)"`));
  assert.ok(match, `bootstrap must declare $${name}`);
  return match[1];
}

function githubApi(endpoint) {
  return JSON.parse(execFileSync("gh", ["api", endpoint], {
    encoding: "utf8",
    maxBuffer: 4 * 1024 * 1024,
    windowsHide: true,
  }));
}

function readPinnedFile(relative, revision) {
  const item = githubApi(
    `repos/jiezeng2004-design/XJTU-Codex-Theme/contents/${relative}?ref=${revision}`,
  );
  assert.equal(item.type, "file", `pinned path must be a file: ${relative}`);
  assert.equal(item.encoding, "base64", `pinned file must use base64 API encoding: ${relative}`);
  return Buffer.from(item.content.replace(/\s/g, ""), "base64").toString("utf8");
}

const bootstrap = read("skills/codex-skin-maker/scripts/bootstrap-workspace.ps1");
const environmentCheck = read("skills/codex-skin-maker/scripts/check-environment.ps1");
const repository = extract(bootstrap, "TrustedRepository");
const tag = extract(bootstrap, "TrustedTag");
const revision = extract(bootstrap, "TrustedRevision");

assert.equal(repository, officialRepository, "bootstrap must pin the official repository");
assert.equal(tag, expectedTag, "bootstrap and release tests must use the same immutable tag");
assert.match(revision, /^[0-9a-f]{40}$/i, "TrustedRevision must be a full 40-character Git SHA");
assert.match(bootstrap, /-c core\.autocrlf=false clone --depth 1 --branch \$TrustedTag -- \$TrustedRepository \$Destination/,
  "Git bootstrap must clone the trusted tag from the trusted repository");
assert.match(bootstrap, /codeload\.github\.com\/jiezeng2004-design\/XJTU-Codex-Theme\/zip\/\$TrustedRevision/,
  "ZIP bootstrap must download the same trusted revision");
assert.match(bootstrap, /Get-Command node\.exe/,
  "ZIP bootstrap must retain a Node.js HTTPS fallback for Windows Schannel failures");
assert.match(bootstrap, /Start-Process\s+-FilePath\s+\$gh\.Source/,
  "ZIP bootstrap must retain a GitHub CLI fallback for restricted HTTPS environments");
assert.match(bootstrap, /revision = \$TrustedRevision/,
  "ZIP source receipt must record the same trusted revision");
assert.match(bootstrap, /Write-SourceReceipt -Path \$Destination -Source "git"/,
  "Git bootstrap must write the same trusted source receipt");
assert.match(bootstrap, /older v0\.2\.1 workspace/, "bootstrap must identify the legacy workspace explicitly");
assert.match(bootstrap, /will not be overwritten or deleted/, "legacy upgrade guidance must preserve the old workspace");

for (const name of ["TrustedRepository", "TrustedTag", "TrustedRevision"]) {
  assert.equal(extract(environmentCheck, name), extract(bootstrap, name),
    `environment check and bootstrap must use the same ${name}`);
}
assert.match(environmentCheck, /\$receipt\.repository/, "environment receipt must validate the official repository");
assert.match(environmentCheck, /\$receipt\.tag/, "environment receipt must validate the immutable tag");
assert.match(environmentCheck, /\$receipt\.revision/, "environment receipt must validate the exact revision");

const tagRef = githubApi(
  `repos/jiezeng2004-design/XJTU-Codex-Theme/git/ref/tags/${encodeURIComponent(tag)}`,
);
assert.equal(tagRef.object?.type, "commit", "release tag must resolve directly to a commit");
assert.equal(tagRef.object?.sha, revision, "release tag must resolve to TrustedRevision");

const pinned = new Map();
for (const relative of requiredPinnedFiles) {
  pinned.set(relative, readPinnedFile(relative, revision));
}

const runtime = pinned.get("engine/src/runtime.mjs");
assert.match(runtime, /function safeThemeSummary\(mode\)/, "pinned runtime must safely summarize invalid manifests");
assert.match(runtime, /export async function disableTheme/, "pinned runtime must retain recovery");
assert.match(runtime, /pulse\(RESTORE_EXPRESSION, \{ allowExisting: true \}\)/,
  "pinned runtime must restore through an existing trusted Inspector");

const engineTests = pinned.get("engine/tests/engine.test.mjs");
assert.match(engineTests, /keeps recovery available when a theme is unavailable/,
  "pinned tests must cover invalid-manifest recovery");
assert.match(engineTests, /renderer payload must include the active theme id/,
  "pinned tests must cover custom active theme IDs");

const assetCheck = pinned.get("scripts/check-theme-assets.mjs");
assert.match(assetCheck, /\^\[a-z0-9\]\[a-z0-9-\]/,
  "pinned asset check must accept custom theme IDs");
assert.match(assetCheck, /startsWith\("xjtu-academic-"\)/,
  "pinned asset check must scope the built-in ID equality check");

for (const relative of [
  "README.md",
  "docs/CODEX_SKIN_MAKER.md",
  "skills/codex-skin-maker/SKILL.md",
]) {
  const text = read(relative);
  assert.ok(text.includes(expectedTag), `${relative} must declare ${expectedTag}`);
  assert.doesNotMatch(text, /已验证 `v0\.2\.1`|latest[^\n]*v0\.2\.1/i,
    `${relative} must not present v0.2.1 as the latest Skin Maker workspace`);
}

assert.ok(read("docs/COMPATIBILITY.md").includes(`| ${expectedTag} |`),
  "compatibility matrix must include the pinned release candidate");

console.log(`PASS Skin Maker release pin ${tag} -> ${revision}`);
