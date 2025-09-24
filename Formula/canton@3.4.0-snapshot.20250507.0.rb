require "json"

class CantonAT340Snapshot202505070 < Formula
  desc "Blockchain protocol implementation from Digital Asset (version 3.4.0-snapshot.20250507.0)"
  homepage "https://www.canton.network/"

  url "https://github.com/digital-asset/daml/releases/download/v3.4.0-snapshot.20250507.0/canton-open-source-3.4.0-snapshot.20250429.15866.0.vc8f10812.tar.gz"
  sha256 "80a3f585ead3b003991ffd0429054a412b3443c9a1a183816386716ff20f9b99"
  version "3.4.0-snapshot.20250507.0"
  license "Apache-2.0"

  # Java 11+ is required (recommend 17 for best compatibility)
  depends_on "openjdk@17" => :recommended

  def install
    prefix.install Dir["*"]

    # Create a version info file for reference
    (prefix/"VERSION_INFO.txt").write <<~EOS
      Canton Version: 3.4.0-snapshot.20250429.15866.0.vc8f10812
      DAML Tag: v3.4.0-snapshot.20250507.0
      Pre-release: Yes
      Installed: #{Time.now}
    EOS
  end

  def caveats
    <<~EOS
      Canton 3.4.0-snapshot.20250429.15866.0.vc8f10812 (pre-release) has been installed.
      DAML Release Tag: v3.4.0-snapshot.20250507.0

      Canton requires Java 11 or later. You may need to set JAVA_HOME:
        export JAVA_HOME=$(/usr/libexec/java_home -v 11)

      Or if using Homebrew's OpenJDK:
        export JAVA_HOME="#{Formula["openjdk@17"].opt_prefix}/libexec/openjdk.jdk/Contents/Home"

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