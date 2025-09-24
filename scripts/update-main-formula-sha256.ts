#!/usr/bin/env bun
/**
 * Update the main canton.rb formula with the latest version info
 *
 * This script updates:
 * - The hardcoded fallback values in the formula
 * - Synchronizes with the canton-versions.json manifest
 *
 * Usage: bun run scripts/update-main-formula-sha256.ts
 */

import { readFile, writeFile } from "node:fs/promises";

async function updateMainFormula() {
  console.log("📝 Updating main formula with latest version info...");

  // Read the manifest
  const manifest = JSON.parse(await readFile("canton-versions.json", "utf-8"));

  // Sort versions by published_at date to get the actual latest
  const sortedVersions = Object.entries(manifest.versions).sort((a, b) => {
    const dateA = new Date(a[1].published_at);
    const dateB = new Date(b[1].published_at);
    return dateB.getTime() - dateA.getTime(); // Sort descending (latest first)
  });

  const latest = sortedVersions[0];

  if (!latest) {
    console.error("❌ No versions found in manifest");
    process.exit(1);
  }

  const [tag, info] = latest as [string, any];

  console.log(`Latest version: ${tag}`);
  console.log(`Canton version: ${info.canton_version}`);
  console.log(`SHA256: ${info.sha256}`);

  // Read the formula
  const formulaPath = "Formula/canton.rb";
  let formulaContent = await readFile(formulaPath, "utf-8");

  // Update the hardcoded fallback values in the formula
  // This is the block that starts with "# Auto-updated by GitHub Actions"
  const fallbackPattern = /# Last resort hardcoded fallback[\s\S]*?\{[\s\S]*?\}/m;
  const fallbackMatch = formulaContent.match(fallbackPattern);

  if (fallbackMatch) {
    // Detect the indent level from the matched content
    const indentMatch = fallbackMatch[0].match(/\n(\s*)\{/);
    const indent = indentMatch ? indentMatch[1] : "      ";

    const newFallback = `# Last resort hardcoded fallback (should be kept in sync via updates)
${indent}# Auto-updated by GitHub Actions - DO NOT MODIFY MANUALLY
${indent}{
${indent}  daml_tag: "${tag}",
${indent}  canton_version: "${info.canton_version}",
${indent}  download_url: "${info.download_url}",
${indent}  sha256: "${info.sha256}",
${indent}  is_prerelease: ${info.is_prerelease ? "true" : "false"}
${indent}}`;

    formulaContent = formulaContent.replace(fallbackPattern, newFallback);

    // Write back the formula
    await writeFile(formulaPath, formulaContent);

    console.log(`✅ Updated canton.rb with latest version info:`);
    console.log(`   - Tag: ${tag}`);
    console.log(`   - Canton: ${info.canton_version}`);
    console.log(`   - SHA256: ${info.sha256.substring(0, 12)}...`);

    // Output for GitHub Actions
    if (process.env.GITHUB_OUTPUT) {
      await writeFile(
        process.env.GITHUB_OUTPUT,
        `formula_updated=true\ntag=${tag}\nsha256=${info.sha256}\ncanton_version=${info.canton_version}\n`,
        { flag: 'a' }
      );
    }
  } else {
    console.warn("⚠️ Fallback block not found in formula");
    console.warn("Formula may have been modified. Please check the structure.");
    process.exit(1);
  }
}

// Run update
updateMainFormula().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});