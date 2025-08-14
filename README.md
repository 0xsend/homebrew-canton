# Homebrew Canton Formula

A Homebrew formula for installing Canton, the blockchain protocol implementation from Digital Asset.

## Features

- 🚀 **Latest Pre-release by Default**: Automatically installs the latest pre-release from DAML
- 📦 **Version Selection**: Install any specific Canton release using versioned formulas
- 🔄 **Multiple Versions**: Support for installing and switching between multiple Canton versions
- ☕ **Java Integration**: Works with system Java 11+ or Homebrew OpenJDK
- 📦 **Complete Installation**: Includes binaries, configs, docs, and examples
- 🤖 **Automated Updates**: GitHub Actions tracks and updates Canton releases

## Installation

### Install Latest Pre-release (Default)

The formula automatically fetches and installs the latest pre-release version from DAML:

```bash
# Add this tap to Homebrew
brew tap 0xsend/homebrew-canton

# Install latest Canton pre-release
brew install canton
```

### Install Specific Version

You can install a specific DAML release version using versioned formulas:

```bash
# Example: Install specific DAML release v3.4.0-snapshot.20250813.1
brew tap 0xsend/homebrew-canton
brew install canton@3.4.0-snapshot.20250813.1

# Or create a versioned formula first
ruby scripts/create-versioned-formula.rb 3.4.0-snapshot.20250813.1
brew install ./Formula/canton@3.4.0-snapshot.20250813.1.rb
```

To see available versions:

```bash
# List all available Canton versions
bun run scripts/canton-versions.ts all

# Show current/latest version
bun run scripts/canton-versions.ts current

# List pre-release versions only
bun run scripts/canton-versions.ts prerelease

# List stable versions only
bun run scripts/canton-versions.ts stable
```

### Switch Between Versions

If you have multiple Canton versions installed:

```bash
# Unlink current version
brew unlink canton

# Link a specific version
brew link canton@3.4.0-snapshot.20250813.1

# Check current version
canton --version
```

## Usage

After installation, Canton is available as the `canton` command:

```bash
# Show Canton help
canton --help

# Start Canton with a config
canton -c /opt/homebrew/etc/canton/config/simple-topology.conf

# Check version info
cat /opt/homebrew/opt/canton/VERSION_INFO.txt
```

## Java Requirements

Canton requires Java 11 or later. The formula recommends OpenJDK 17 but will work with any compatible Java installation.

### Using Homebrew Java

```bash
# Install recommended Java version
brew install openjdk@17

# Set JAVA_HOME (add to your shell profile)
export JAVA_HOME="$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home"
```

### Using System Java

```bash
# Verify Java version (must be 11+)
java -version

# Set JAVA_HOME if needed
export JAVA_HOME=$(/usr/libexec/java_home -v 11)
```

## Configuration

The formula installs the complete Canton distribution:

- **Binary**: `/opt/homebrew/bin/canton`
- **Config files**: `/opt/homebrew/etc/canton/config/`
- **Examples**: `/opt/homebrew/etc/canton/examples/`
- **Documentation**: `/opt/homebrew/etc/canton/docs/`
- **Libraries**: `/opt/homebrew/etc/canton/lib/`
- **Version Info**: `/opt/homebrew/opt/canton/VERSION_INFO.txt`

## Version Management

### Dynamic Formula

The main `canton` formula dynamically fetches the latest pre-release from the DAML repository at install time. This ensures you always get the most recent pre-release version.

### Version Manifest

To improve performance and cache SHA256 hashes, generate a version manifest:

```bash
# Generate manifest for top 10 releases
bun run scripts/generate-version-manifest.ts 10

# This creates canton-versions.json with cached version information
```

### Creating Versioned Formulas

To create a formula for a specific DAML release:

```bash
# Generate formula for a specific DAML tag
ruby scripts/create-versioned-formula.rb v3.4.0-snapshot.20250813.1

# The script will:
# 1. Fetch release information from GitHub
# 2. Find the Canton asset in the release
# 3. Calculate or retrieve SHA256 hash from manifest
# 4. Generate Formula/canton@3.4.0-snapshot.20250813.1.rb

# Install the generated formula
brew install ./Formula/canton@3.4.0-snapshot.20250813.1.rb
```

## Automated Canton Tracking

This repository automatically tracks Canton releases from Digital Asset:

- **Automated Updates**: GitHub Actions runs every 12 hours to check for new Canton releases
- **Version Management**: Creates git tags and GitHub releases for each Canton version
- **SHA256 Verification**: Automatically calculates and verifies package hashes
- **Formula Updates**: Keeps the Homebrew formula current with latest releases

### Manual Updates

```bash
# Update the formula to the latest version
bun run scripts/update-homebrew-formula.ts

# Check for new versions
bun run scripts/canton-versions.ts current

# Generate version manifest
bun run scripts/generate-version-manifest.ts
```

## Development

### Scripts

This repository includes several utility scripts:

- `scripts/canton-versions.ts` - Fetch and manage Canton release versions
- `scripts/create-versioned-formula.rb` - Create versioned formulas for specific DAML releases
- `scripts/generate-version-manifest.ts` - Generate a manifest with SHA256 hashes
- `scripts/update-homebrew-formula.ts` - Update the formula to the latest version
- `scripts/install-canton-version.sh` - Wrapper script to install a specific version
- `scripts/get-canton-release-info.rb` - Helper to fetch release info from GitHub API

### Testing the Formula

```bash
# Test the formula syntax
brew audit --formula canton

# Test installation locally
brew install --build-from-source ./Formula/canton.rb

# Test with verbose output
brew install --build-from-source --verbose ./Formula/canton.rb
```

### Formula Structure

- `Formula/canton.rb` - Main formula that dynamically installs the latest pre-release
- `Formula/canton@<version>.rb` - Version-specific formulas (generated on demand)
- `canton-versions.json` - Manifest file with cached version information and SHA256 hashes

## Troubleshooting

### Java Issues

```bash
# Check Java version
java -version

# Check JAVA_HOME
echo $JAVA_HOME

# List available Java versions (macOS)
/usr/libexec/java_home -V
```

### Canton Issues

```bash
# Check Canton installation
canton --help

# Check file permissions
ls -la $(which canton)

# Verify Canton can find Java
canton --version

# Check version information
cat /opt/homebrew/opt/canton/VERSION_INFO.txt
```

### Formula Issues

```bash
# Debug formula installation
brew install --build-from-source --verbose ./Formula/canton.rb

# Check formula syntax
brew audit ./Formula/canton.rb

# Clean up failed installs
brew uninstall canton
brew cleanup

# Re-tap the repository
brew untap 0xsend/canton
brew tap 0xsend/homebrew-canton
```

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This Homebrew formula is licensed under Apache-2.0, same as Canton itself.