#!/bin/bash
# Helper script to install a specific Canton version
# Usage: ./install-canton-version.sh <version>
# Example: ./install-canton-version.sh v3.4.0-snapshot.20250813.1

set -e

VERSION=$1

if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 v3.4.0-snapshot.20250813.1"
  echo ""
  echo "Available versions:"
  jq -r '.versions | keys[]' canton-versions.json | sort | tail -10
  exit 1
fi

# Normalize version (ensure it has 'v' prefix)
if [[ ! "$VERSION" =~ ^v ]]; then
  VERSION="v$VERSION"
fi

# Clean version for formula name (remove 'v' prefix)
FORMULA_VERSION=${VERSION#v}

echo "📦 Installing Canton $VERSION..."

# Check if formula exists
if [ -f "Formula/canton@$FORMULA_VERSION.rb" ]; then
  echo "✅ Formula already exists"
else
  echo "⚙️  Generating formula..."
  bun run scripts/generate-versioned-formula.ts "$VERSION"
fi

# Install the formula
echo "🚀 Installing canton@$FORMULA_VERSION..."
# Note: We don't use HOMEBREW_NO_INSTALL_FROM_API here to allow
# Homebrew to fetch dependencies from the API
brew install "canton@$FORMULA_VERSION"

echo ""
echo "✅ Canton $VERSION installed successfully!"
echo ""
echo "To use this version:"
echo "  canton --version"
echo ""
echo "To switch between versions:"
echo "  brew unlink canton"
echo "  brew link canton@$FORMULA_VERSION"