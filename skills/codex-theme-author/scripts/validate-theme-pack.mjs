#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const root = path.resolve(process.argv[2] || process.cwd());
const colorPattern = /^(#[0-9a-f]{6}|rgba?\([^\r\n;{}]+\))$/i;
const percentPattern = /^(?:100|[0-9]{1,2}|1[01][0-9]|120)%$/;
const allowedTopLevel = new Set(["schemaVersion", "id", "name", "variant", "image", "colors", "layout"]);
const colorKeys = ["background", "panel", "accent", "text", "muted", "line"];
const layoutKeys = [
  "positionX", "zoom", "bodyScrimStart", "bodyScrimEnd", "mainScrimStart",
  "mainScrimEnd", "sidebarScrimStart", "sidebarScrimEnd", "conversationWallpaper",
];

function imageSize(filename) {
  const data = fs.readFileSync(filename);
  if (data.length >= 24 && data.subarray(1, 4).toString("ascii") === "PNG") {
    return { width: data.readUInt32BE(16), height: data.readUInt32BE(20) };
  }
  if (data.length >= 4 && data[0] === 0xff && data[1] === 0xd8) {
    let offset = 2;
    const sof = new Set([0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf]);
    while (offset + 8 < data.length) {
      if (data[offset] !== 0xff) { offset += 1; continue; }
      const marker = data[offset + 1];
      offset += 2;
      if (marker === 0xd8 || marker === 0xd9) continue;
      if (offset + 2 > data.length) break;
      const length = data.readUInt16BE(offset);
      if (length < 2 || offset + length > data.length) break;
      if (sof.has(marker)) return { height: data.readUInt16BE(offset + 3), width: data.readUInt16BE(offset + 5) };
      offset += length;
    }
  }
  return null;
}

function validateMode(mode) {
  const errors = [];
  const warnings = [];
  const manifestPath = path.join(root, "engine", "themes", `${mode}.json`);
  if (!fs.existsSync(manifestPath)) return { mode, manifestPath, errors: [`Missing manifest: ${manifestPath}`], warnings };

  let manifest;
  try { manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8")); }
  catch (error) { return { mode, manifestPath, errors: [`Invalid JSON: ${error.message}`], warnings }; }

  for (const key of Object.keys(manifest)) if (!allowedTopLevel.has(key)) errors.push(`Unknown top-level field: ${key}`);
  if (manifest.schemaVersion !== 1) errors.push("schemaVersion must be 1");
  if (!/^[a-z0-9][a-z0-9-]{0,63}$/.test(manifest.id || "")) errors.push("id must use lowercase letters, digits, and hyphens");
  if (typeof manifest.name !== "string" || !manifest.name.trim()) errors.push("name must be a non-empty string");
  if (manifest.variant !== mode) errors.push(`variant must be ${mode}`);

  if (!manifest.colors || typeof manifest.colors !== "object") errors.push("colors must be an object");
  else {
    for (const key of colorKeys) if (!colorPattern.test(manifest.colors[key] || "")) errors.push(`Invalid color: ${key}`);
    for (const key of Object.keys(manifest.colors)) if (!colorKeys.includes(key)) errors.push(`Unknown color field: ${key}`);
  }

  if (!manifest.layout || typeof manifest.layout !== "object") errors.push("layout must be an object");
  else {
    for (const key of layoutKeys.filter((item) => item !== "conversationWallpaper")) {
      if (!percentPattern.test(manifest.layout[key] || "")) errors.push(`Invalid percentage: ${key}`);
    }
    if (typeof manifest.layout.conversationWallpaper !== "boolean") errors.push("conversationWallpaper must be boolean");
    for (const key of Object.keys(manifest.layout)) if (!layoutKeys.includes(key)) errors.push(`Unknown layout field: ${key}`);
  }

  let resolvedImage = null;
  let dimensions = null;
  if (typeof manifest.image !== "string" || !manifest.image.trim()) errors.push("image must be a relative path");
  else {
    resolvedImage = path.resolve(path.dirname(manifestPath), manifest.image);
    const relative = path.relative(root, resolvedImage);
    if (relative.startsWith("..") || path.isAbsolute(relative)) errors.push("image must stay inside the repository");
    else if (!fs.existsSync(resolvedImage) || !fs.statSync(resolvedImage).isFile()) errors.push(`Image not found: ${resolvedImage}`);
    else {
      const extension = path.extname(resolvedImage).toLowerCase();
      if (![".jpg", ".jpeg", ".png", ".webp"].includes(extension)) errors.push(`Unsupported image format: ${extension}`);
      dimensions = imageSize(resolvedImage);
      if (!dimensions) warnings.push("Image dimensions could not be read; inspect the image manually");
      else {
        const ratio = dimensions.width / dimensions.height;
        if (dimensions.width < 1600 || dimensions.height < 900) warnings.push(`Image is smaller than 1600x900: ${dimensions.width}x${dimensions.height}`);
        if (Math.abs(ratio - 16 / 9) > 0.08) warnings.push(`Image is not close to 16:9: ${dimensions.width}x${dimensions.height}`);
      }
    }
  }

  return { mode, manifestPath, imagePath: resolvedImage, dimensions, errors, warnings };
}

const results = [validateMode("dark"), validateMode("light")];
const valid = results.every((result) => result.errors.length === 0);
console.log(JSON.stringify({ valid, root, results }, null, 2));
if (!valid) process.exitCode = 1;
