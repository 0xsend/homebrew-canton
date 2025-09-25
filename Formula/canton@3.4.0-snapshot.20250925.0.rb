require "json"

class CantonAT340Snapshot202509250 < Formula
  desc "Blockchain protocol implementation from Digital Asset (version 3.4.0-snapshot.20250925.0)"
  homepage "https://www.canton.network/"

  url "https://github.com/digital-asset/daml/releases/download/v3.4.0-snapshot.20250925.0/canton-open-source-3.4.0-snapshot.20250922.16951.0.v1eb3f268.tar.gz"
  sha256 "e0f59a7b5015b56479ef4786662c5935a0fee9ac803465bb0f70bdc6c3bf4dff"
  version "3.4.0-snapshot.20250925.0"
  license "Apache-2.0"

  # Java 11+ is required - we mark as optional to avoid dependency resolution issues
  # Users should ensure Java is installed separately
  depends_on "openjdk@17" => :optional

  def install
    prefix.install Dir["*"]

    # Create a version info file for reference
    (prefix/"VERSION_INFO.txt").write <<~EOS
      Canton Version: 3.4.0-snapshot.20250922.16951.0.v1eb3f268
      DAML Tag: v3.4.0-snapshot.20250925.0
      Pre-release: Yes
      Installed: #{Time.now}
    EOS
  end

  def caveats
    <<~EOS
      Canton 3.4.0-snapshot.20250922.16951.0.v1eb3f268 (pre-release) has been installed.
      DAML Release Tag: v3.4.0-snapshot.20250925.0

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