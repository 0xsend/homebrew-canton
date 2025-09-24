require "json"

class CantonAT340Snapshot202508131 < Formula
  desc "Blockchain protocol implementation from Digital Asset (version 3.4.0-snapshot.20250813.1)"
  homepage "https://www.canton.network/"

  url "https://github.com/digital-asset/daml/releases/download/v3.4.0-snapshot.20250813.1/canton-open-source-3.4.0-snapshot.20250806.16573.0.vf9366406.tar.gz"
  sha256 "a1a188e8353c169f8c91b41fccf46239328b98667a445e544041c9fc836412a0"
  version "3.4.0-snapshot.20250813.1"
  license "Apache-2.0"

  # Java 11+ is required - we mark as optional to avoid dependency resolution issues
  # Users should ensure Java is installed separately
  depends_on "openjdk@17" => :optional

  def install
    prefix.install Dir["*"]

    # Create a version info file for reference
    (prefix/"VERSION_INFO.txt").write <<~EOS
      Canton Version: 3.4.0-snapshot.20250806.16573.0.vf9366406
      DAML Tag: v3.4.0-snapshot.20250813.1
      Pre-release: Yes
      Installed: #{Time.now}
    EOS
  end

  def caveats
    <<~EOS
      Canton 3.4.0-snapshot.20250806.16573.0.vf9366406 (pre-release) has been installed.
      DAML Release Tag: v3.4.0-snapshot.20250813.1

      ⚠️  IMPORTANT: Canton requires Java 11 or later to run.

      Check if Java is installed:
        java -version

      If not installed, install via Homebrew:
        brew install openjdk@17

      Then set JAVA_HOME:
        export JAVA_HOME="$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home"

      Or use system Java (if available):
        export JAVA_HOME=$(/usr/libexec/java_home -v 11)

      Configuration files are available at:
        #{prefix}/config/

      Examples are available at:
        #{prefix}/examples/

      Documentation is available at:
        #{prefix}/docs/

      Version info saved at:
        #{prefix}/VERSION_INFO.txt
    EOS
  end

  test do
    # Test that the binary exists and is executable
    assert_path_exists bin/"canton"
    assert_predicate bin/"canton", :executable?

    # Test that Java is available (required for Canton to run)
    java_version = shell_output("java -version 2>&1")
    assert_match(/version "(1\.)?(8|9|11|17|21)/, java_version)

    # Test that Canton can show help (basic functionality test)
    output = shell_output("#{bin}/canton --help 2>&1")
    assert_match(/Canton/, output)

    # Check version info file was created
    assert_path_exists prefix/"VERSION_INFO.txt"
  end
end