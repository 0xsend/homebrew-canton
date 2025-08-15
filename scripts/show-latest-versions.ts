#!/usr/bin/env bun

const manifest = require("../canton-versions.json");
const versions = Object.entries(manifest.versions).slice(0, 5);
versions.forEach(([tag, info]) => {
  const type = info.is_prerelease ? "pre-release" : "stable";
  console.log(`${tag} - ${info.canton_version} (${type})`);
});