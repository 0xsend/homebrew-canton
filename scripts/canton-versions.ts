#!/usr/bin/env bun
/**
 * Canton Version Management
 *
 * Central registry for fetching and managing Canton release versions.
 * Provides single source of truth for version alignment across repositories.
 *
 * Usage:
 *   import { getCurrentCantonVersion, getAllCantonVersions } from './canton-versions';
 */
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

/**
 * Fetches all Canton releases from Digital Asset GitHub API
 */
export async function getAllCantonVersions(): Promise<CantonRelease[]> {
	console.log("Fetching Canton releases from Digital Asset GitHub...");

	const response = await fetch(
		"https://api.github.com/repos/digital-asset/daml/releases",
	);
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

	// Filter for releases that have Canton assets
	const cantonReleases = releases
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

			// Extract Canton version from asset name: canton-open-source-{version}.tar.gz
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
		// Sort by published date (newest first), prioritizing prereleases
		.sort((a: CantonRelease, b: CantonRelease) => {
			// First, prioritize prereleases (snapshots)
			if (a.isPrerelease && !b.isPrerelease) return -1;
			if (!a.isPrerelease && b.isPrerelease) return 1;

			// Then sort by published date (newest first)
			return (
				new Date(b.publishedAt).getTime() - new Date(a.publishedAt).getTime()
			);
		});

	console.log(`Found ${cantonReleases.length} Canton releases`);
	return cantonReleases;
}

/**
 * Gets the current/latest Canton version (prioritizes prereleases)
 */
export async function getCurrentCantonVersion(): Promise<CantonRelease> {
	const releases = await getAllCantonVersions();

	if (releases.length === 0) {
		throw new Error("No Canton releases found");
	}

	const currentRelease = releases[0];
	if (!currentRelease) {
		throw new Error("No Canton releases found");
	}

	return currentRelease; // Already sorted with prereleases first
}

/**
 * Gets a specific Canton version by version string
 */
export async function getCantonVersion(
	version: string,
): Promise<CantonRelease | null> {
	const releases = await getAllCantonVersions();
	return releases.find((r) => r.cantonVersion === version) || null;
}

/**
 * Gets a specific Canton release by DAML tag
 */
export async function getCantonReleaseByDamlTag(
	damlTag: string,
): Promise<CantonRelease | null> {
	const releases = await getAllCantonVersions();
	return releases.find((r) => r.damlTag === damlTag) || null;
}

/**
 * Gets Canton release info from local manifest (if available)
 */
export async function getCantonReleaseFromManifest(
	damlTag: string,
): Promise<CantonRelease | null> {
	try {
		const manifestPath = new URL("../canton-versions.json", import.meta.url).pathname;
		const manifestData = await Bun.file(manifestPath).text();
		const manifest = JSON.parse(manifestData);
		
		const versionInfo = manifest.versions[damlTag];
		if (versionInfo) {
			return {
				cantonVersion: versionInfo.cantonVersion,
				damlTag: damlTag,
				downloadUrl: versionInfo.downloadUrl,
				sha256: versionInfo.sha256,
				isPrerelease: versionInfo.isPrerelease,
				publishedAt: versionInfo.publishedAt,
				htmlUrl: `https://github.com/digital-asset/daml/releases/tag/${damlTag}`
			};
		}
	} catch (error) {
		// Manifest not found or invalid
	}
	
	// Fall back to fetching from API
	return getCantonReleaseByDamlTag(damlTag);
}

/**
 * Calculates SHA256 hash for a Canton release by downloading it
 */
export async function calculateSha256(downloadUrl: string): Promise<string> {
	console.log(`Calculating SHA256 for ${downloadUrl}...`);

	const response = await fetch(downloadUrl);
	if (!response.ok) {
		throw new Error(
			`Failed to download for SHA256 calculation: ${response.statusText}`,
		);
	}

	const buffer = await response.arrayBuffer();
	const hash = createHash("sha256");
	hash.update(new Uint8Array(buffer));

	const sha256 = hash.digest("hex");
	console.log(`SHA256: ${sha256}`);

	return sha256;
}

/**
 * Gets Canton versions with SHA256 hashes calculated
 */
export async function getCantonVersionsWithHashes(
	count: number = 5,
): Promise<CantonRelease[]> {
	const releases = await getAllCantonVersions();
	const topReleases = releases.slice(0, count);

	// Calculate SHA256 for each release
	const releasesWithHashes = await Promise.all(
		topReleases.map(async (release) => ({
			...release,
			sha256: await calculateSha256(release.downloadUrl),
		})),
	);

	return releasesWithHashes;
}

/**
 * Filters for stable releases only (non-prereleases)
 */
export async function getStableCantonVersions(): Promise<CantonRelease[]> {
	const releases = await getAllCantonVersions();
	return releases.filter((r) => !r.isPrerelease);
}

/**
 * Filters for prerelease versions only (snapshots)
 */
export async function getPrereleaseCantonVersions(): Promise<CantonRelease[]> {
	const releases = await getAllCantonVersions();
	return releases.filter((r) => r.isPrerelease);
}

// CLI interface when run directly
if (import.meta.main) {
	const command = process.argv[2];

	switch (command) {
		case "current":
			getCurrentCantonVersion()
				.then((release) => {
					console.log(`Current Canton Version: ${release.cantonVersion}`);
					console.log(`DAML Tag: ${release.damlTag}`);
					console.log(`Is Prerelease: ${release.isPrerelease}`);
					console.log(`Download URL: ${release.downloadUrl}`);
				})
				.catch(console.error);
			break;

		case "all":
			getAllCantonVersions()
				.then((releases) => {
					console.log("All Canton Versions:");
					releases.forEach((release, index) => {
						console.log(
							`${index + 1}. ${release.cantonVersion} (${release.damlTag}) ${release.isPrerelease ? "[PRERELEASE]" : "[STABLE]"}`,
						);
					});
				})
				.catch(console.error);
			break;

		case "stable":
			getStableCantonVersions()
				.then((releases) => {
					console.log("Stable Canton Versions:");
					releases.forEach((release, index) => {
						console.log(
							`${index + 1}. ${release.cantonVersion} (${release.damlTag})`,
						);
					});
				})
				.catch(console.error);
			break;

		case "prerelease":
			getPrereleaseCantonVersions()
				.then((releases) => {
					console.log("Prerelease Canton Versions:");
					releases.forEach((release, index) => {
						console.log(
							`${index + 1}. ${release.cantonVersion} (${release.damlTag})`,
						);
					});
				})
				.catch(console.error);
			break;

		case "sha256": {
			const url = process.argv[3];
			if (!url) {
				console.error(
					"Usage: bun run canton-versions.ts sha256 <download-url>",
				);
				process.exit(1);
			}
			calculateSha256(url)
				.then((hash) => {
					console.log(`SHA256: ${hash}`);
				})
				.catch(console.error);
			break;
		}

		default:
			console.log("Usage: bun run canton-versions.ts <command>");
			console.log("Commands:");
			console.log("  current    - Show current/latest Canton version");
			console.log("  all        - List all Canton versions");
			console.log("  stable     - List stable versions only");
			console.log("  prerelease - List prerelease versions only");
			console.log("  sha256 <url> - Calculate SHA256 for a download URL");
	}
}
