#!/usr/bin/env bun

const manifest = require("../canton-versions.json");
const total = Object.keys(manifest.versions).length;
const prerelease = Object.values(manifest.versions).filter(v => v.is_prerelease).length;
const stable = total - prerelease;
console.log(`Total versions: ${total}`);
console.log(`Pre-releases: ${prerelease}`);
console.log(`Stable releases: ${stable}`);
console.log(`Last updated: ${manifest.updated_at}`);