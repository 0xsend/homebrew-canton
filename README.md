# Homebrew Canton Formula

A Homebrew formula for installing Canton, the blockchain protocol implementation from Digital Asset.

## Features

- 🚀 **Snapshot Support**: Installs pre-release snapshot versions from GitHub
- ☕ **Java Integration**: Works with system Java 11+ or Homebrew OpenJDK
- 📦 **Complete Installation**: Includes binaries, configs, docs, and examples
- 🔄 **Auto-Updates**: `--HEAD` installs fetch the latest snapshot automatically

## Installation

### Install from this Tap

```bash
# Add this tap to Homebrew
brew tap your-username/canton homebrew-canton

# Install Canton (default snapshot version)
brew install canton

# Or install latest snapshot
brew install canton --HEAD
```

### Direct Formula Installation

```bash
# Install directly from the formula file
brew install --build-from-source ./Formula/canton.rb

# Or install latest snapshot
brew install --build-from-source --HEAD ./Formula/canton.rb
```

## Usage

After installation, Canton is available as the `canton` command:

```bash
# Show Canton help
canton --help

# Start Canton with a config
canton -c /opt/homebrew/etc/canton/config/simple-topology.conf

# Run Canton interactively
canton --auto-connect-local
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

### Default Installation

The formula defaults to the snapshot version matching the `fetch-canton.ts` script:
- **DAML Release**: `v3.4.0-snapshot.20250625.0`
- **Canton Version**: `3.4.0-snapshot.20250617.16217.0.vbdf62919`
- **SHA256**: `5f1bf64d5d3bf50c4dd379bca44d46069e6ece43377177a6e09b4ff0979f640d`

### HEAD Installation

Using `--HEAD` fetches the latest snapshot release from the GitHub API:
- Automatically finds the newest pre-release
- Downloads the `canton-open-source-*.tar.gz` asset
- No version pinning - always gets the latest

## Development

### Testing the Formula

```bash
# Test the formula syntax
brew audit --strict ./Formula/canton.rb

# Test installation locally
brew install --build-from-source ./Formula/canton.rb

# Test with verbose output
brew install --build-from-source --verbose ./Formula/canton.rb

# Test HEAD installation
brew install --build-from-source --HEAD ./Formula/canton.rb
```

### Updating Versions

To update the default version:

1. Update the `url`, `sha256`, and `version` in the formula
2. Get the SHA256 with: `curl -L <url> | shasum -a 256`
3. Test the updated formula

### Formula Structure

```ruby
class Canton < Formula
  # Metadata
  desc "Canton blockchain protocol implementation from Digital Asset"
  homepage "https://www.canton.network/"
  license "Apache-2.0"
  
  # Version handling
  if build.head?
    # HEAD: fetch latest snapshot via GitHub API
  else
    # Default: specific snapshot version with checksum
  end
  
  # Dependencies
  depends_on "openjdk@17" => :recommended
  
  # Installation methods
  def install_release        # Standard version install
  def install_latest_snapshot # HEAD install with API lookup
end
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

## Contributing

1. Fork this repository
2. Make your changes to `Formula/canton.rb`
3. Test thoroughly with `brew audit` and local installation
4. Submit a pull request

## License

This Homebrew formula is released under the MIT License. Canton itself is licensed under Apache 2.0.