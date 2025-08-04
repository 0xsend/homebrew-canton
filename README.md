# Homebrew Canton Formula

A Homebrew formula for installing Canton, the blockchain protocol implementation from Digital Asset.

## Features

- 📦 **Snapshot Installation**: Installs the specific snapshot version
- ☕ **Java Integration**: Works with system Java 11+ or Homebrew OpenJDK
- 📦 **Complete Installation**: Includes binaries, configs, docs, and examples

## Installation

### Install from this Tap

```bash
# Add this tap to Homebrew
brew tap 0xsend/homebrew-canton

# Install Canton
brew install canton
```

### Direct Formula Installation

```bash
# Install directly from the formula file
brew install --build-from-source ./Formula/canton.rb
```

## Usage

After installation, Canton is available as the `canton` command:

```bash
# Show Canton help
canton --help

# Start Canton with a config
canton -c /opt/homebrew/etc/canton/config/simple-topology.conf
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

## Version Information

The formula installs a specific snapshot version:

- **DAML Release**: `v3.4.0-snapshot.20250710.0`
- **Canton Version**: `3.4.0-snapshot.20250707.16366.0.vf80131e0`
- **SHA256**: `395d51792fbd1ac38e21754cf21a3cde094a149218707c00e0e0ab0a67aa3a8d`

## Automated Canton Tracking

This repository automatically tracks Canton releases from Digital Asset:

- **Automated Updates**: GitHub Actions runs every 12 hours to check for new Canton releases
- **Version Management**: Creates git tags and GitHub releases for each Canton version
- **SHA256 Verification**: Automatically calculates and verifies package hashes
- **Formula Updates**: Keeps the Homebrew formula current with latest releases

### Manual Updates

```bash
# Run manual update
./update.sh

# Check for new versions
bun run scripts/canton-versions.ts current

# List all available versions
bun run scripts/canton-versions.ts all
```

## Development

### Testing the Formula

```bash
# Test the formula syntax
brew audit --strict ./Formula/canton.rb

# Test installation locally
brew install --build-from-source ./Formula/canton.rb

# Test with verbose output
brew install --build-from-source --verbose ./Formula/canton.rb
```

### Version Management

The repository uses TypeScript scripts with Bun for version management:

```bash
# Check current Canton version
bun run scripts/canton-versions.ts current

# Get all versions with details
bun run scripts/canton-versions.ts all

# Calculate SHA256 for a specific URL
bun run scripts/canton-versions.ts sha256 <download-url>
```

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
```
