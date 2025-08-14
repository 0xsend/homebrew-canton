#!/usr/bin/env bun
/**
 * Generate Version Manifest
 * 
 * Creates a JSON manifest of Canton releases with pre-calculated SHA256 hashes.
 * This speeds up formula generation by caching the SHA256 values.
 */
import * as fs from "node:fs/promises";
import * as path from "node:path";
import { getAllCantonVersions, calculateSha256, type CantonRelease } from "./canton-versions";

const MANIFEST_PATH = path.join(process.cwd(), "canton-versions.json");

interface VersionManifest {
  updated_at: string;
  versions: {
    [damlTag: string]: {
      canton_version: string;
      download_url: string;
      sha256: string;
      is_prerelease: boolean;
      published_at: string;
    };
  };
}

async function loadManifest(): Promise<VersionManifest> {
  try {
    const content = await fs.readFile(MANIFEST_PATH, "utf-8");
    return JSON.parse(content);
  } catch {
    return {
      updated_at: new Date().toISOString(),
      versions: {}
    };
  }
}

async function saveManifest(manifest: VersionManifest): Promise<void> {
  manifest.updated_at = new Date().toISOString();
  await fs.writeFile(MANIFEST_PATH, JSON.stringify(manifest, null, 2));
}

async function generateManifest(limit: number = 10): Promise<void> {
  console.log("=== Canton Version Manifest Generator ===");
  
  // Load existing manifest
  const manifest = await loadManifest();
  console.log(`Existing manifest has ${Object.keys(manifest.versions).length} versions`);
  
  // Fetch all Canton releases
  const releases = await getAllCantonVersions();
  console.log(`Found ${releases.length} total Canton releases`);
  
  // Process top N releases
  const topReleases = releases.slice(0, limit);
  console.log(`Processing top ${topReleases.length} releases...`);
  
  let newVersions = 0;
  let skippedVersions = 0;
  
  for (const release of topReleases) {
    // Skip if already in manifest with SHA256
    if (manifest.versions[release.damlTag]?.sha256) {
      console.log(`✓ ${release.damlTag} already in manifest`);
      skippedVersions++;
      continue;
    }
    
    console.log(`\nProcessing ${release.damlTag}...`);
    console.log(`  Canton version: ${release.cantonVersion}`);
    console.log(`  Type: ${release.isPrerelease ? "Pre-release" : "Stable"}`);
    
    try {
      // Calculate SHA256
      const sha256 = await calculateSha256(release.downloadUrl);
      
      // Add to manifest
      manifest.versions[release.damlTag] = {
        canton_version: release.cantonVersion,
        download_url: release.downloadUrl,
        sha256: sha256,
        is_prerelease: release.isPrerelease,
        published_at: release.publishedAt
      };
      
      console.log(`  ✅ Added to manifest with SHA256: ${sha256.substring(0, 12)}...`);
      newVersions++;
      
      // Save after each successful addition
      await saveManifest(manifest);
      
    } catch (error) {
      console.error(`  ❌ Failed to process: ${error}`);
    }
  }
  
  console.log("\n=== Summary ===");
  console.log(`New versions added: ${newVersions}`);
  console.log(`Versions skipped (already in manifest): ${skippedVersions}`);
  console.log(`Total versions in manifest: ${Object.keys(manifest.versions).length}`);
  console.log(`Manifest saved to: ${MANIFEST_PATH}`);
}

// CLI interface
if (import.meta.main) {
  const limitArg = process.argv[2];
  const limit = limitArg ? parseInt(limitArg) : 10;
  
  if (isNaN(limit) || limit < 1) {
    console.error("Usage: bun run generate-version-manifest.ts [limit]");
    console.error("  limit: Number of releases to process (default: 10)");
    process.exit(1);
  }
  
  generateManifest(limit).catch(console.error);
}

export { generateManifest, loadManifest, saveManifest };