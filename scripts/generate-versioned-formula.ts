#!/usr/bin/env bun
/**
 * Generate a versioned Canton formula from the template
 *
 * Usage: bun run scripts/generate-versioned-formula.ts <version-tag>
 * Example: bun run scripts/generate-versioned-formula.ts v3.4.0-snapshot.20250813.1
 */

import { readFile, writeFile, exists } from "node:fs/promises";
import { join } from "node:path";

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

async function loadTemplate(): Promise<string> {
  const templatePath = join(import.meta.dir, "..", "Formula", "canton.rb.template");
  return await readFile(templatePath, "utf-8");
}

function sanitizeVersionForClass(version: string): string {
  // Homebrew expects a specific format for versioned formula class names
  // The class must match: CantonAT + version with special formatting
  const cleaned = version
    .replace(/^v/, "")
    .replace(/\./g, "")  // Remove all dots
    .replace(/-/g, "");  // Remove all hyphens

  // Capitalize first letter of 'snapshot' to match Homebrew's expectation
  return cleaned.replace(/snapshot/i, "Snapshot");
}

function generateFormula(
  template: string,
  versionTag: string,
  info: VersionInfo,
  isLatest: boolean = false
): string {
  const cleanVersion = versionTag.replace(/^v/, "");

  // Determine class suffix and version type
  const classSuffix = isLatest ? "" : `AT${sanitizeVersionForClass(cleanVersion)}`;
  const versionType = isLatest ? "latest pre-release" : `version ${cleanVersion}`;

  // Replace all placeholders
  return template
    .replace(/{{CLASS_SUFFIX}}/g, classSuffix)
    .replace(/{{VERSION_TYPE}}/g, versionType)
    .replace(/{{DOWNLOAD_URL}}/g, info.download_url)
    .replace(/{{SHA256}}/g, info.sha256)
    .replace(/{{VERSION}}/g, cleanVersion)
    .replace(/{{CANTON_VERSION}}/g, info.canton_version)
    .replace(/{{DAML_TAG}}/g, versionTag)
    .replace(/{{IS_PRERELEASE}}/g, info.is_prerelease ? "Yes" : "No")
    .replace(/{{RELEASE_TYPE}}/g, info.is_prerelease ? "pre-release" : "stable");
}

async function generateVersionedFormula(versionTag: string) {
  // Normalize version tag
  const normalizedTag = versionTag.startsWith("v") ? versionTag : `v${versionTag}`;

  // Load manifest and template
  const manifest = await loadManifest();
  const template = await loadTemplate();

  // Find version in manifest
  const versionInfo = manifest.versions[normalizedTag];
  if (!versionInfo) {
    throw new Error(`Version ${normalizedTag} not found in manifest`);
  }

  // Generate formula content
  const formulaContent = generateFormula(template, normalizedTag, versionInfo);

  // Determine output filename
  const cleanVersion = normalizedTag.replace(/^v/, "");
  const outputPath = join(
    import.meta.dir,
    "..",
    "Formula",
    `canton@${cleanVersion}.rb`
  );

  // Check if formula already exists
  if (await exists(outputPath)) {
    console.log(`⚠️  Formula already exists: ${outputPath}`);
    const response = prompt("Overwrite? (y/N): ");
    if (response?.toLowerCase() !== 'y') {
      console.log("Skipping...");
      return;
    }
  }

  // Write formula
  await writeFile(outputPath, formulaContent);
  console.log(`✅ Generated formula: ${outputPath}`);
  console.log(`   Version: ${normalizedTag}`);
  console.log(`   Canton: ${versionInfo.canton_version}`);
  console.log(`   SHA256: ${versionInfo.sha256.substring(0, 12)}...`);

  // Show installation command
  console.log(`\n📦 Installation command:`);
  console.log(`   brew install canton@${cleanVersion}`);
}

async function generateLatestFormula() {
  const manifest = await loadManifest();
  const template = await loadTemplate();

  // Find latest version by published_at date
  const sortedVersions = Object.entries(manifest.versions).sort((a, b) => {
    const dateA = new Date(a[1].published_at);
    const dateB = new Date(b[1].published_at);
    return dateB.getTime() - dateA.getTime();
  });

  if (sortedVersions.length === 0) {
    throw new Error("No versions found in manifest");
  }

  const [latestTag, latestInfo] = sortedVersions[0];

  // Generate the main formula (without version suffix)
  const formulaContent = generateFormula(template, latestTag, latestInfo, true);

  const outputPath = join(import.meta.dir, "..", "Formula", "canton.rb");
  await writeFile(outputPath, formulaContent);

  console.log(`✅ Generated main formula: ${outputPath}`);
  console.log(`   Latest version: ${latestTag}`);
  console.log(`   Canton: ${latestInfo.canton_version}`);
}

// Main execution
async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.log("Usage: bun run scripts/generate-versioned-formula.ts <version-tag|--latest|--all>");
    console.log("");
    console.log("Options:");
    console.log("  <version-tag>  Generate formula for specific version (e.g., v3.4.0-snapshot.20250813.1)");
    console.log("  --latest       Generate main formula for latest version");
    console.log("  --all          Generate formulas for all versions in manifest");
    console.log("");
    console.log("Examples:");
    console.log("  bun run scripts/generate-versioned-formula.ts v3.4.0-snapshot.20250813.1");
    console.log("  bun run scripts/generate-versioned-formula.ts --latest");
    process.exit(1);
  }

  try {
    if (args[0] === "--latest") {
      await generateLatestFormula();
    } else if (args[0] === "--all") {
      // Generate all versioned formulas
      const manifest = await loadManifest();
      const versions = Object.keys(manifest.versions);

      console.log(`Generating formulas for ${versions.length} versions...`);

      for (const version of versions) {
        await generateVersionedFormula(version);
      }

      // Also generate the main formula
      await generateLatestFormula();

      console.log(`\n✅ Generated ${versions.length + 1} formulas`);
    } else {
      await generateVersionedFormula(args[0]);
    }
  } catch (error) {
    console.error(`❌ Error: ${error.message}`);
    process.exit(1);
  }
}

main();