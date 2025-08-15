#!/usr/bin/env bun
/**
 * Update the main canton.rb formula with the latest SHA256
 * 
 * Usage: bun run scripts/update-main-formula-sha256.ts
 */

import { readFile, writeFile } from "node:fs/promises";

async function updateMainFormula() {
  console.log("📝 Updating main formula with latest SHA256...");
  
  // Read the manifest
  const manifest = JSON.parse(await readFile("canton-versions.json", "utf-8"));
  const latest = Object.entries(manifest.versions)[0];
  
  if (!latest) {
    console.error("❌ No versions found in manifest");
    process.exit(1);
  }
  
  const [tag, info] = latest as [string, any];
  const sha256 = info.sha256;
  
  console.log(`Latest version: ${tag}`);
  console.log(`SHA256: ${sha256}`);
  
  // Read the formula
  const formulaPath = "Formula/canton.rb";
  let formulaContent = await readFile(formulaPath, "utf-8");
  
  // Update the SHA256
  const sha256Pattern = /sha256 "[a-f0-9]{64}"/;
  const currentSha256 = formulaContent.match(sha256Pattern)?.[0];
  
  if (currentSha256) {
    formulaContent = formulaContent.replace(sha256Pattern, `sha256 "${sha256}"`);
    
    // Write back the formula
    await writeFile(formulaPath, formulaContent);
    
    console.log(`✅ Updated canton.rb with SHA256: ${sha256.substring(0, 12)}...`);
    
    // Output for GitHub Actions
    if (process.env.GITHUB_OUTPUT) {
      await writeFile(process.env.GITHUB_OUTPUT, `sha256_updated=true\ntag=${tag}\nsha256=${sha256}\n`, { flag: 'a' });
    }
  } else {
    console.warn("⚠️ SHA256 field not found in formula");
    process.exit(1);
  }
}

// Run update
updateMainFormula().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});