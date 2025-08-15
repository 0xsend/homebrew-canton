#!/usr/bin/env bun
/**
 * Create versioned formulas for new Canton releases
 * 
 * Usage: bun run scripts/create-new-formulas.ts [count]
 * Default: Creates formulas for top 5 releases
 */

import { readFile, readdir } from "node:fs/promises";
import { spawn } from "node:child_process";

// Get count from command line argument or default to 5
const count = parseInt(process.argv[2] || "5");

async function createFormulas() {
  console.log(`🏗️ Creating versioned formulas for top ${count} releases...`);
  
  const manifest = JSON.parse(await readFile("canton-versions.json", "utf-8"));
  const existingFormulas = await readdir("Formula");
  
  // Check top N versions
  const versions = Object.entries(manifest.versions).slice(0, count);
  let created = 0;
  let skipped = 0;
  
  for (const [tag, info] of versions as [string, any][]) {
    const versionTag = tag.replace(/^v/, "");
    const formulaName = `canton@${versionTag}.rb`;
    
    if (existingFormulas.includes(formulaName)) {
      console.log(`✓ ${formulaName} already exists`);
      skipped++;
      continue;
    }
    
    console.log(`Creating formula for ${tag}...`);
    
    try {
      // Use the Ruby script to create the formula
      const child = spawn("ruby", ["scripts/create-versioned-formula.rb", tag]);
      
      // Capture output
      let output = "";
      child.stdout.on("data", (data) => {
        output += data.toString();
      });
      
      child.stderr.on("data", (data) => {
        output += data.toString();
      });
      
      // Wait for completion
      await new Promise<void>((resolve, reject) => {
        child.on("close", (code) => {
          if (code === 0) {
            console.log(`✅ Created ${formulaName}`);
            created++;
            resolve();
          } else {
            console.error(`❌ Failed to create ${formulaName}:`);
            console.error(output);
            reject(new Error(`Process exited with code ${code}`));
          }
        });
        
        child.on("error", (error) => {
          console.error(`❌ Failed to spawn process: ${error.message}`);
          reject(error);
        });
      });
    } catch (error: any) {
      console.error(`❌ Failed to create ${formulaName}: ${error.message}`);
    }
  }
  
  console.log(`\nSummary:`);
  console.log(`  Created: ${created} new formulas`);
  console.log(`  Skipped: ${skipped} existing formulas`);
  console.log(`  Total:   ${versions.length} versions checked`);
  
  if (created > 0) {
    console.log(`\n✅ Successfully created ${created} new versioned formulas`);
  } else {
    console.log(`\nℹ️ No new formulas needed`);
  }
}

// Run formula creation
createFormulas().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});