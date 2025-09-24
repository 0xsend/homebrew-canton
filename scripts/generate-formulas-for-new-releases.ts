#!/usr/bin/env bun
/**
 * Generate formulas for new Canton releases
 *
 * This script checks for new versions in the manifest and generates
 * formulas only for versions that don't already have formulas.
 *
 * Usage: bun run scripts/generate-formulas-for-new-releases.ts
 */

import { readFile, readdir, exists } from "node:fs/promises";
import { join } from "node:path";
import { $ } from "bun";

interface VersionInfo {
  canton_version: string;
  download_url: string;
  sha256: string;
  is_prerelease: boolean;
  published_at: string;
}

interface Manifest {
  versions: Record<string, VersionInfo>;
}

async function loadManifest(): Promise<Manifest> {
  const manifestPath = join(import.meta.dir, "..", "canton-versions.json");
  const content = await readFile(manifestPath, "utf-8");
  return JSON.parse(content);
}

async function getExistingFormulas(): Promise<Set<string>> {
  const formulaDir = join(import.meta.dir, "..", "Formula");
  const files = await readdir(formulaDir);

  const versions = new Set<string>();

  for (const file of files) {
    // Match versioned formulas like canton@3.4.0-snapshot.20250813.1.rb
    const match = file.match(/^canton@(.+)\.rb$/);
    if (match) {
      versions.add(match[1]);
    }
  }

  return versions;
}

async function generateFormulasForNewReleases() {
  console.log("🔍 Checking for new Canton releases...");

  // Load manifest
  const manifest = await loadManifest();
  const allVersions = Object.keys(manifest.versions);

  // Get existing formulas
  const existingFormulas = await getExistingFormulas();

  // Find new versions (without formulas)
  const newVersions: string[] = [];

  for (const versionTag of allVersions) {
    const cleanVersion = versionTag.replace(/^v/, "");
    if (!existingFormulas.has(cleanVersion)) {
      newVersions.push(versionTag);
    }
  }

  if (newVersions.length === 0) {
    console.log("✅ No new versions found. All formulas are up to date.");
    return [];
  }

  console.log(`📦 Found ${newVersions.length} new version(s) to generate formulas for:`);
  newVersions.forEach(v => console.log(`   - ${v}`));

  // Generate formulas for new versions
  const generated: string[] = [];

  for (const version of newVersions) {
    try {
      console.log(`\n⚙️  Generating formula for ${version}...`);
      await $`bun run ${join(import.meta.dir, "generate-versioned-formula.ts")} ${version}`;
      generated.push(version);
    } catch (error) {
      console.error(`❌ Failed to generate formula for ${version}: ${error.message}`);
    }
  }

  // Always regenerate the main formula to ensure it points to latest
  console.log("\n⚙️  Updating main formula to latest version...");
  await $`bun run ${join(import.meta.dir, "generate-versioned-formula.ts")} --latest`;

  if (generated.length > 0) {
    console.log(`\n✅ Successfully generated ${generated.length} new formula(s)`);
    console.log("\n📋 Summary of new formulas:");
    generated.forEach(v => {
      const cleanVersion = v.replace(/^v/, "");
      console.log(`   brew install canton@${cleanVersion}`);
    });
  }

  return generated;
}

// Main execution
async function main() {
  try {
    const newFormulas = await generateFormulasForNewReleases();

    // Exit with code 0 if successful
    process.exit(0);
  } catch (error) {
    console.error(`❌ Error: ${error.message}`);
    process.exit(1);
  }
}

main();