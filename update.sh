#!/bin/bash
set -e

echo "=== Canton Homebrew Formula Update Script ==="

# Get current Canton version from our latest GitHub release
echo "Checking current version from GitHub releases..."
CURRENT_RELEASE=$(curl -s "https://api.github.com/repos/0xsend/homebrew-canton/releases/latest")

if [ "$CURRENT_RELEASE" = "null" ] || echo "$CURRENT_RELEASE" | grep -q '"message": "Not Found"'; then
  echo "No current releases found, will create first release"
  CURRENT_VERSION=""
else
  # Extract Canton version from tag (format: canton-{version})
  CURRENT_TAG=$(echo "$CURRENT_RELEASE" | jq -r '.tag_name')
  CURRENT_VERSION=${CURRENT_TAG#canton-}
  echo "Current version: $CURRENT_VERSION"
fi

# Get top 5 releases from Digital Asset that contain Canton
echo "Fetching top 5 Canton releases from Digital Asset..."
ALL_RELEASES=$(curl -s "https://api.github.com/repos/digital-asset/daml/releases" | \
  jq -r '[.[] | select(.assets[] | select(.name | contains("canton-open-source") and endswith(".tar.gz")))] | .[0:5]')

if [ "$ALL_RELEASES" = "null" ] || [ "$ALL_RELEASES" = "[]" ]; then
  echo "No Canton releases found"
  exit 0
fi

# Get existing tags to avoid duplicates
echo "Checking existing tags..."
EXISTING_TAGS=$(git tag -l | sed 's/^canton-//' || echo "")

# Process each of the top 5 releases
printf "Processing top 5 Canton releases...\n"
PROCESSED_COUNT=0
PROCESSED_VERSIONS=""

# Use process substitution to avoid subshell issues
while IFS= read -r release; do
  VERSION=$(echo "$release" | jq -r '.assets[] | select(.name | contains("canton-open-source") and endswith(".tar.gz")) | .name' | sed 's/canton-open-source-\(.*\)\.tar\.gz/\1/')
  RELEASE_URL=$(echo "$release" | jq -r '.html_url')
  DOWNLOAD_URL=$(echo "$release" | jq -r '.assets[] | select(.name | contains("canton-open-source") and endswith(".tar.gz")) | .browser_download_url')
  
  printf "\n=== Processing Canton version: %s ===\n" "$VERSION"
  
  # Check if this version already exists as a tag or was already processed
  if echo "$EXISTING_TAGS" | grep -q "^$VERSION$"; then
    echo "Tag canton-$VERSION already exists, skipping..."
    continue
  fi
  
  # Check if we already processed this version in this run
  if echo "$PROCESSED_VERSIONS" | grep -q "$VERSION"; then
    echo "Version $VERSION already processed in this run, skipping..."
    continue
  fi
  
  PROCESSED_VERSIONS="$PROCESSED_VERSIONS $VERSION"
  
  echo "New version found: $VERSION"
  
  # Download and calculate SHA256
  echo "Downloading $DOWNLOAD_URL to calculate SHA256..."
  TEMP_FILE="canton-release-$VERSION.tar.gz"
  if command -v wget >/dev/null 2>&1; then
    wget -q "$DOWNLOAD_URL" -O "$TEMP_FILE"
  else
    curl -s -L "$DOWNLOAD_URL" -o "$TEMP_FILE"
  fi
  
  # Calculate SHA256 (different command on macOS vs Linux)
  if [[ "$OSTYPE" == "darwin"* ]]; then
    SHA256=$(shasum -a 256 "$TEMP_FILE" | cut -d' ' -f1)
  else
    SHA256=$(sha256sum "$TEMP_FILE" | cut -d' ' -f1)
  fi
  echo "SHA256: $SHA256"
  
  # Cleanup temp file
  rm -f "$TEMP_FILE"
  
  # Update formula with this version (only for the first/latest version)
  if [ $PROCESSED_COUNT -eq 0 ]; then
    echo "Updating Formula/canton.rb with latest version..."
    # Use different sed syntax for macOS vs Linux
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS
      sed -i '' "s|url \"https://github\.com/digital-asset/daml/releases/download/[^\"]*\"|url \"$DOWNLOAD_URL\"|" Formula/canton.rb
      sed -i '' "s|sha256 \"[a-f0-9]\{64\}\"|sha256 \"$SHA256\"|" Formula/canton.rb
      sed -i '' "s|version \"[^\"]*\"|version \"$VERSION\"|" Formula/canton.rb
    else
      # Linux
      sed -i "s|url \"https://github\.com/digital-asset/daml/releases/download/[^\"]*\"|url \"$DOWNLOAD_URL\"|" Formula/canton.rb
      sed -i "s|sha256 \"[a-f0-9]\{64\}\"|sha256 \"$SHA256\"|" Formula/canton.rb
      sed -i "s|version \"[^\"]*\"|version \"$VERSION\"|" Formula/canton.rb
    fi
  fi

  # Only commit and create release if running in CI (GITHUB_TOKEN is set)
  if [ -n "$GITHUB_TOKEN" ]; then
    echo "Running in CI, creating release for $VERSION..."
    
    # Configure git (only once)
    if [ $PROCESSED_COUNT -eq 0 ]; then
      git config --local user.email "action@github.com"
      git config --local user.name "GitHub Action"
    fi
    
    # Create GitHub release and tag for this version
    if ! git tag "canton-$VERSION"; then
      echo "Failed to create tag for $VERSION"
      continue
    fi
    
    if ! git push origin "canton-$VERSION"; then
      echo "Failed to push tag for $VERSION"
      continue
    fi
    
    # Determine if this should be marked as latest (first processed version)
    LATEST_FLAG=""
    if [ $PROCESSED_COUNT -eq 0 ]; then
      LATEST_FLAG="--latest"
    fi
    
    if ! gh release create "canton-$VERSION" \
      --title "Canton $VERSION" \
      --notes "Homebrew formula for Canton version $VERSION.

This release tracks the Canton release from Digital Asset:
- Original Release: $RELEASE_URL
- Canton Version: $VERSION
- SHA256: $SHA256

Install with:
\`\`\`bash
brew tap 0xsend/homebrew-canton
brew install canton
\`\`\`

Or install directly:
\`\`\`bash
brew install 0xsend/homebrew-canton/canton
\`\`\`

🤖 Auto-generated by GitHub Actions" \
      $LATEST_FLAG; then
      echo "Failed to create GitHub release for $VERSION"
      continue
    fi
    
    echo "Successfully created release for Canton $VERSION"
  else
    echo "Running locally, found version $VERSION"
    echo "- URL: $DOWNLOAD_URL"
    echo "- SHA256: $SHA256"
  fi
  
  PROCESSED_COUNT=$((PROCESSED_COUNT + 1))
done < <(echo "$ALL_RELEASES" | jq -c '.[]')

# Commit formula changes if running in CI and we processed any versions
if [ -n "$GITHUB_TOKEN" ] && [ "$PROCESSED_COUNT" -gt 0 ]; then
  printf "\nCommitting formula changes...\n"
  git add Formula/canton.rb
  
  # Check if there are any changes to commit
  if ! git diff --cached --quiet; then
    if ! git commit -m "feat: update Canton formula to latest versions

Processed $PROCESSED_COUNT Canton releases

🤖 Generated with GitHub Actions"; then
      echo "Failed to commit formula changes"
      exit 1
    fi
    
    if ! git push; then
      echo "Failed to push formula changes"
      exit 1
    fi
    
    echo "Successfully committed formula changes"
  else
    echo "No formula changes to commit"
  fi
fi

if [ "$PROCESSED_COUNT" -eq 0 ]; then
  printf "\nNo new Canton versions to process\n"
else
  printf "\nProcessed %d new Canton versions\n" "$PROCESSED_COUNT"
fi

echo "=== Canton release scan complete ==="
