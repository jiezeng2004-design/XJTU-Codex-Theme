import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const variants = ["dark", "light"];

function readJson(file) {
  let value;
  try {
    value = JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (error) {
    throw new Error(`${path.relative(projectRoot, file)} is not valid JSON: ${error.message}`);
  }
  return value;
}

function resolveProjectFile(base, relative, label) {
  assert.equal(typeof relative, "string", `${label} must be a string`);
  const resolved = path.resolve(base, relative);
  const rel = path.relative(projectRoot, resolved);
  assert.ok(rel && !rel.startsWith("..") && !path.isAbsolute(rel), `${label} escapes the project: ${relative}`);
  assert.ok(fs.existsSync(resolved), `${label} does not exist: ${rel}`);
  assert.ok(fs.statSync(resolved).isFile(), `${label} is not a file: ${rel}`);
  return resolved;
}

for (const variant of variants) {
  const sourceDir = path.join(projectRoot, "themes", `xjtu-academic-${variant}`);
  const sourceManifestPath = path.join(sourceDir, "theme.json");
  const source = readJson(sourceManifestPath);

  assert.equal(source.schemaVersion, 1, `${variant} source schemaVersion`);
  assert.equal(source.id, `xjtu-academic-${variant}`, `${variant} source id`);
  assert.equal(source.targets?.codex?.options?.baseTheme?.mode, variant, `${variant} source mode`);
  resolveProjectFile(sourceDir, source.targets?.codex?.css, `${variant} Codex CSS`);

  const images = Object.entries(source.images || {});
  assert.ok(images.length > 0, `${variant} source must declare at least one image`);
  for (const [name, relative] of images) {
    resolveProjectFile(sourceDir, relative, `${variant} image ${name}`);
  }

  const engineManifestPath = path.join(projectRoot, "engine", "themes", `${variant}.json`);
  const engine = readJson(engineManifestPath);
  assert.equal(engine.schemaVersion, 1, `${variant} engine schemaVersion`);
  assert.match(engine.id || "", /^[a-z0-9][a-z0-9-]{0,63}$/, `${variant} engine id`);
  if (engine.id.startsWith("xjtu-academic-")) {
    assert.equal(engine.id, source.id, `${variant} XJTU manifest id`);
  }
  assert.equal(engine.variant, variant, `${variant} engine variant`);
  resolveProjectFile(path.dirname(engineManifestPath), engine.image, `${variant} engine image`);
}

console.log("PASS theme JSON and resource paths");
