#!/usr/bin/env bun
/**
 * Generate Version Manifest
 * 
 * Creates a JSON manifest of Canton releases with pre-calculated SHA256 hashes.
 * This speeds up formula generation by caching the SHA256 values.
 */
import * as fs from "node:fs/promises";
import * as path from "node:path";
import { createHash } from "node:crypto";

export interface CantonRelease {
  cantonVersion: string;
  damlTag: string;
  downloadUrl: string;
  sha256?: string;
  isPrerelease: boolean;
  publishedAt: string;
  htmlUrl: string;
}

async function getAllCantonVersions(): Promise<CantonRelease[]> {
  const response = await fetch("https://api.github.com/repos/digital-asset/daml/releases");
  if (!response.ok) {
    throw new Error(`Failed to fetch releases: ${response.statusText}`);
  }

  interface GitHubRelease {
    tag_name: string;
    prerelease: boolean;
    published_at: string;
    html_url: string;
    assets: Array<{
      name: string;
      browser_download_url: string;
    }>;
  }

  const releases = (await response.json()) as GitHubRelease[];

  return releases
    .filter((release) =>
      release.assets?.some(
        (asset) =>
          asset.name.includes("canton-open-source") &&
          asset.name.endsWith(".tar.gz"),
      ),
    )
    .map((release) => {
      const cantonAsset = release.assets.find(
        (asset) =>
          asset.name.includes("canton-open-source") &&
          asset.name.endsWith(".tar.gz"),
      );

      const cantonVersion = cantonAsset.name.replace(
        /canton-open-source-(.+)\.tar\.gz/,
        "$1",
      );

      return {
        cantonVersion,
        damlTag: release.tag_name,
        downloadUrl: cantonAsset.browser_download_url,
        isPrerelease: release.prerelease,
        publishedAt: release.published_at,
        htmlUrl: release.html_url,
      } as CantonRelease;
    })
    .sort((a: CantonRelease, b: CantonRelease) => {
      if (a.isPrerelease && !b.isPrerelease) return -1;
      if (!a.isPrerelease && b.isPrerelease) return 1;
      return new Date(b.publishedAt).getTime() - new Date(a.publishedAt).getTime();
    });
}

async function calculateSha256(downloadUrl: string): Promise<string> {
  const response = await fetch(downloadUrl);
  if (!response.ok) {
    throw new Error(`Failed to download for SHA256 calculation: ${response.statusText}`);
  }

  const buffer = await response.arrayBuffer();
  const hash = createHash("sha256");
  hash.update(new Uint8Array(buffer));
  return hash.digest("hex");
}

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