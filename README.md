# Homebrew Canton Formula

A Homebrew formula for installing Canton, the blockchain protocol implementation from Digital Asset.

## Features

- 🚀 **Latest Pre-release by Default**: Automatically installs the latest pre-release from DAML
- 📦 **Versioned Formulas**: Install specific versions using `canton@version` syntax
- 🔄 **JSON Manifest**: All versions and SHA256 hashes tracked in canton-versions.json
- ☕ **Java Integration**: Works with system Java 11+ or Homebrew OpenJDK
- 📦 **Complete Installation**: Includes binaries, configs, docs, and examples
- 🤖 **Automated Updates**: GitHub Actions generates formulas for new releases

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

Install specific Canton versions using versioned formulas:

```bash
# Install a specific version
brew install canton@3.4.0-snapshot.20250813.1

# For local development/testing
export HOMEBREW_NO_INSTALL_FROM_API=1
brew install --build-from-source canton@3.4.0-snapshot.20250709.0
```

To see available versions:

```bash
# List all available versions from manifest
jq -r '.versions | keys[]' canton-versions.json | sort

# Show version details for a specific release
jq '.versions["v3.4.0-snapshot.20250813.1"]' canton-versions.json

# Count available versions
jq '.versions | length' canton-versions.json
```

### Switch Between Versions

To install a different version when one is already installed:

```bash
# Check current version
canton --version
cat /opt/homebrew/opt/canton/VERSION_INFO.txt

# Uninstall current version
brew uninstall canton

# Install a different version
CANTON_VERSION=v3.4.0-snapshot.20250709.0 brew install canton

# Verify new version
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

### Formula Architecture

#### Template-Based Formula Generation

The repository uses a template-based approach for formula management:

1. **Template Formula** (`Formula/canton.rb.template`): Defines the structure for all formulas
2. **Automated Generation**: Scripts generate versioned formulas from the template
3. **Version Manifest** (`canton-versions.json`): Source of truth for all versions and SHA256 hashes
4. **GitHub Actions**: Automatically generates formulas for new releases

#### Generated Formulas

- **Main Formula** (`canton.rb`): Always points to the latest release
- **Versioned Formulas** (`canton@version.rb`): Specific version installations

This approach ensures consistency across all formulas while making it easy to add new versions.

## Automated Canton Tracking

This repository automatically tracks Canton releases from Digital Asset:

- **Automated Updates**: GitHub Actions runs every 12 hours to check for new Canton releases
- **Version Management**: Creates git tags and GitHub releases for each Canton version
- **SHA256 Verification**: Automatically calculates and verifies package hashes
- **Formula Updates**: Keeps the Homebrew formula current with latest releases

### Manual Updates

```bash
# Generate version manifest
bun run scripts/generate-version-manifest.ts
```

## Development

### Scripts

This repository includes several utility scripts:

- `scripts/generate-version-manifest.ts` - Generate/update the manifest with SHA256 hashes
- `scripts/generate-versioned-formula.ts` - Generate formulas from template
- `scripts/generate-formulas-for-new-releases.ts` - Auto-generate formulas for new releases
- `scripts/verify-sha256.ts` - Verify SHA256 hashes in manifest
- `scripts/show-latest-versions.ts` - Display latest versions from manifest
- `scripts/show-manifest-stats.ts` - Show statistics about the version manifest

### Testing the Formula

```bash
# Test the formula syntax
brew audit --formula canton

# Test installation of latest version
export HOMEBREW_NO_INSTALL_FROM_API=1
brew install --build-from-source canton

# Test installation of specific version
brew install --build-from-source canton@3.4.0-snapshot.20250813.1

# Generate a new versioned formula
bun run scripts/generate-versioned-formula.ts v3.4.0-snapshot.20250709.0

# Test with verbose output for debugging
brew install --build-from-source --verbose canton
```

### Formula Structure

- `Formula/canton.rb.template` - Template for generating all formulas
- `Formula/canton.rb` - Main formula for latest version (auto-generated)
- `Formula/canton@<version>.rb` - Versioned formulas (auto-generated on demand)
- `canton-versions.json` - Manifest file with all available versions and their SHA256 hashes

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