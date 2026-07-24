import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

const skills = [
  {
    id: "codex-theme-author",
    required: [
      "SKILL.md",
      "agents/openai.yaml",
      "references/theme-schema.md",
      "scripts/validate-theme-pack.mjs",
    ],
  },
  {
    id: "codex-skin-maker",
    required: [
      "SKILL.md",
      "LICENSE.txt",
      "agents/openai.yaml",
      "references/user-flow.md",
      "references/theme-guidelines.md",
      "references/compatibility-and-safety.md",
      "references/error-messages.md",
      "scripts/bootstrap-workspace.ps1",
      "scripts/check-environment.ps1",
    ],
  },
];

function readText(file) {
  assert.ok(fs.existsSync(file), `missing file: ${path.relative(projectRoot, file)}`);
  assert.ok(fs.statSync(file).isFile(), `expected file: ${path.relative(projectRoot, file)}`);
  return fs.readFileSync(file, "utf8");
}

function parseFrontmatter(markdown, label) {
  const match = markdown.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/);
  assert.ok(match, `${label} must begin with YAML frontmatter`);

  const name = match[1].match(/^name:\s*(.+)$/m)?.[1]?.trim();
  const description = match[1].match(/^description:\s*(.+)$/m)?.[1]?.trim();
  assert.ok(name, `${label} frontmatter requires name`);
  assert.ok(description, `${label} frontmatter requires description`);
  return { name, description };
}

for (const skill of skills) {
  const skillRoot = path.join(projectRoot, "skills", skill.id);
  assert.ok(fs.existsSync(skillRoot), `missing skill directory: skills/${skill.id}`);

  for (const relative of skill.required) {
    readText(path.join(skillRoot, relative));
  }

  const skillMarkdown = readText(path.join(skillRoot, "SKILL.md"));
  const frontmatter = parseFrontmatter(skillMarkdown, `${skill.id}/SKILL.md`);
  assert.equal(frontmatter.name, skill.id, `${skill.id} frontmatter name must match directory`);
  assert.match(frontmatter.name, /^[a-z0-9-]{1,64}$/, `${skill.id} name must be a lowercase slug`);
  assert.ok(frontmatter.description.length >= 40, `${skill.id} description is too short`);

  const interfaceYaml = readText(path.join(skillRoot, "agents", "openai.yaml"));
  assert.doesNotMatch(interfaceYaml, /\t/, `${skill.id} openai.yaml must use spaces`);
  assert.match(interfaceYaml, /^interface:\s*$/m, `${skill.id} openai.yaml requires interface`);
  assert.match(interfaceYaml, /^\s+display_name:\s*.+$/m, `${skill.id} requires display_name`);
  assert.match(interfaceYaml, /^\s+short_description:\s*.+$/m, `${skill.id} requires short_description`);
  assert.match(interfaceYaml, /^\s+default_prompt:\s*.+$/m, `${skill.id} requires default_prompt`);
  assert.ok(interfaceYaml.includes(`$${skill.id}`), `${skill.id} default_prompt must invoke its own Skill`);
}

const beginnerSkill = readText(path.join(projectRoot, "skills", "codex-skin-maker", "SKILL.md"));
for (const requiredPhrase of ["明确", "preview", "verify", "disable", "Dry Run"]) {
  assert.ok(beginnerSkill.includes(requiredPhrase), `codex-skin-maker safety flow must mention ${requiredPhrase}`);
}

const bootstrapScript = readText(path.join(projectRoot, "skills", "codex-skin-maker", "scripts", "bootstrap-workspace.ps1"));
assert.match(bootstrapScript, /\$TrustedRevision\s*=\s*"[0-9a-f]{40}"/i, "bootstrap must pin a full Git revision");
assert.doesNotMatch(bootstrapScript, /refs\/heads\//i, "bootstrap must not download a mutable branch archive");
assert.doesNotMatch(bootstrapScript, /\bgit\s+pull\b|\bpull\s+--ff-only\b/i, "bootstrap must not update from a mutable branch");
assert.doesNotMatch(bootstrapScript, /Remove-Item\s+-LiteralPath\s+\$Destination(?![A-Za-z0-9_])/i, "bootstrap must not delete the destination");
assert.match(bootstrapScript, /Only the official XJTU Codex Theme repository is supported/, "bootstrap must reject custom remote sources");

const environmentScript = readText(path.join(projectRoot, "skills", "codex-skin-maker", "scripts", "check-environment.ps1"));
assert.match(environmentScript, /workspaceTrusted/, "environment check must report workspace trust");
assert.match(environmentScript, /ConvertTo-RedactedDoctorLine/, "environment check must redact doctor output");
assert.doesNotMatch(environmentScript, /repositoryRoot\s*=\s*\(Resolve-Path/i, "environment check must not emit an absolute repository root");

const authorSkill = readText(path.join(projectRoot, "skills", "codex-theme-author", "SKILL.md"));
assert.match(authorSkill, /advanced Codex Desktop theme manifests/i, "advanced author Skill must target manifest work");
assert.match(authorSkill, /prefer codex-skin-maker/i, "ordinary image requests must route to codex-skin-maker");

console.log("PASS skill package structure and safety workflow");
