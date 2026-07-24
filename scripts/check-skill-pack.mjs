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
  assert.ok(frontmatter.description.length >= 40, `${skill.id} description is too short`);

  const interfaceYaml = readText(path.join(skillRoot, "agents", "openai.yaml"));
  assert.match(interfaceYaml, /^interface:\s*$/m, `${skill.id} openai.yaml requires interface`);
  assert.match(interfaceYaml, /^\s+display_name:\s*.+$/m, `${skill.id} requires display_name`);
  assert.match(interfaceYaml, /^\s+short_description:\s*.+$/m, `${skill.id} requires short_description`);
  assert.match(interfaceYaml, /^\s+default_prompt:\s*.+$/m, `${skill.id} requires default_prompt`);
}

const beginnerSkill = readText(path.join(projectRoot, "skills", "codex-skin-maker", "SKILL.md"));
for (const requiredPhrase of ["明确", "preview", "verify", "disable", "Dry Run"]) {
  assert.ok(beginnerSkill.includes(requiredPhrase), `codex-skin-maker safety flow must mention ${requiredPhrase}`);
}

console.log("PASS skill package structure and safety workflow");
