#!/bin/bash
# Install a specific Canton version from DAML releases
# Usage: ./install-canton-version.sh <daml-tag>

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <daml-tag>"
    echo "Example: $0 v3.2.0"
    echo ""
    echo "To list available versions:"
    echo "  bun run scripts/canton-versions.ts all"
    exit 1
fi

DAML_TAG=$1
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FORMULA_DIR="$SCRIPT_DIR/../Formula"

echo "Installing Canton from DAML release $DAML_TAG..."

# Create versioned formula
echo "Creating versioned formula..."
ruby "$SCRIPT_DIR/create-versioned-formula.rb" "$DAML_TAG"

# Extract version number for formula filename
VERSION_SUFFIX=$(echo "$DAML_TAG" | sed 's/^v//')
FORMULA_FILE="$FORMULA_DIR/canton@${VERSION_SUFFIX}.rb"

if [ ! -f "$FORMULA_FILE" ]; then
    echo "Error: Formula file not created: $FORMULA_FILE"
    exit 1
fi

# Install using Homebrew
echo "Installing with Homebrew..."
brew install --build-from-source "$FORMULA_FILE"

echo ""
echo "Canton $DAML_TAG has been installed successfully!"
echo ""
echo "To use this version:"
echo "  canton --version"
echo ""
echo "If you have multiple versions installed, you can switch between them using:"
echo "  brew unlink canton"
echo "  brew link canton@${VERSION_SUFFIX}"