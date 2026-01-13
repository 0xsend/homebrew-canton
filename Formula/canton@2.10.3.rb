require "json"

class CantonAT2103 < Formula
  desc "Blockchain protocol implementation from Digital Asset (version 2.10.3)"
  homepage "https://www.canton.network/"

  url "https://github.com/digital-asset/daml/releases/download/v2.10.3/canton-open-source-2.10.3.tar.gz"
  sha256 "7aa2dbf1c84c5d65b4eda205e5f19c5c22cbbf8ce5c5e787456700f372b16263"
  version "2.10.3"
  license "Apache-2.0"

  # Java 11+ is required - we mark as optional to avoid dependency resolution issues
  # Users should ensure Java is installed separately
  depends_on "openjdk@17" => :optional

  def install
    prefix.install Dir["*"]

    # Create a version info file for reference
    (prefix/"VERSION_INFO.txt").write <<~EOS
      Canton Version: 2.10.3
      DAML Tag: v2.10.3
      Pre-release: Yes
      Installed: #{Time.now}
    EOS
  end

  def caveats
    <<~EOS
      Canton 2.10.3 (pre-release) has been installed.
      DAML Release Tag: v2.10.3

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