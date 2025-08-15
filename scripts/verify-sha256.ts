#!/usr/bin/env bun
/**
 * Verify SHA256 hashes in the Canton version manifest
 * 
 * Usage: bun run scripts/verify-sha256.ts [count]
 * Default: Verifies top 3 releases
 */

import { readFile } from "node:fs/promises";
import { createHash } from "node:crypto";

// Get count from command line argument or default to 3
const count = parseInt(process.argv[2] || "3");

async function verifyHashes() {
  console.log(`🔐 Verifying SHA256 hashes for top ${count} releases...`);
  
  const manifest = JSON.parse(await readFile("canton-versions.json", "utf-8"));
  let errors = 0;
  
  // Verify top N releases
  const versions = Object.entries(manifest.versions).slice(0, count);
  
  for (const [tag, info] of versions as [string, any][]) {
    console.log(`Verifying ${tag}...`);
    
    try {
      const response = await fetch(info.download_url);
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      
      const buffer = await response.arrayBuffer();
      const hash = createHash("sha256");
      hash.update(new Uint8Array(buffer));
      const calculated = hash.digest("hex");
      
      if (calculated === info.sha256) {
        console.log(`✅ ${tag}: SHA256 verified`);
      } else {
        console.error(`❌ ${tag}: SHA256 mismatch!`);
        console.error(`  Expected: ${info.sha256}`);
        console.error(`  Got:      ${calculated}`);
        errors++;
      }
    } catch (error: any) {
      console.error(`❌ ${tag}: Failed to verify - ${error.message}`);
      errors++;
    }
  }
  
  if (errors > 0) {
    console.error(`\n❌ ${errors} verification error(s) found`);
    process.exit(1);
  } else {
    console.log(`\n✅ All ${versions.length} SHA256 hashes verified successfully`);
  }
}

// Run verification
verifyHashes().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});