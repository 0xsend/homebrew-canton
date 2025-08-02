class Canton < Formula
  desc "Canton blockchain protocol implementation from Digital Asset"
  homepage "https://www.canton.network/"
  license "Apache-2.0"

  url "https://github.com/digital-asset/daml/releases/download/v3.4.0-snapshot.20250723.0/canton-open-source-3.4.0-snapshot.20250715.16432.0.vcd4fe703.tar.gz"
  sha256 "04f33ccadd9651b4be8fbbbd0c33039795a8ee86e3e07d2d9955200bce4ce74a"
  version "3.4.0-snapshot.20250715.16432.0.vcd4fe703"

  # Java 11+ is required (recommend 17 for best compatibility)
  depends_on "openjdk@17" => :recommended

  def install
    prefix.install Dir["*"]
  end

  def caveats
    <<~EOS
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
    EOS
  end

  test do
    # Test that the binary exists and is executable
    assert_predicate bin/"canton", :exist?
    assert_predicate bin/"canton", :executable?

    # Test that Java is available (required for Canton to run)
    java_version = shell_output("java -version 2>&1")
    assert_match(/version "[1-9][0-9]"/, java_version)

    # Test that Canton can show help (basic functionality test)
    output = shell_output("#{bin}/canton --help 2>&1", 0)
    assert_match(/Canton/, output)
  end
end