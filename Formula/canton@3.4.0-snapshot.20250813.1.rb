class CantonAT340snapshot202508131 < Formula
  desc "Blockchain protocol implementation from Digital Asset (v3.4.0-snapshot.20250813.1)"
  homepage "https://www.canton.network/"
  
  url "https://github.com/digital-asset/daml/releases/download/v3.4.0-snapshot.20250813.1/canton-open-source-3.4.0-snapshot.20250806.16573.0.vf9366406.tar.gz"
  sha256 "a1a188e8353c169f8c91b41fccf46239328b98667a445e544041c9fc836412a0"
  version "3.4.0-snapshot.20250813.1"
  license "Apache-2.0"
  
  # Java 11+ is required (recommend 17 for best compatibility)
  depends_on "openjdk@17" => :recommended
  
  # Conflicts with main canton formula
  conflicts_with "canton", because: "both install the same binaries"
  
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
    release_type = true ? "pre-release" : "stable"
    
    <<~EOS
      Canton 3.4.0-snapshot.20250806.16573.0.vf9366406 (#{release_type}) has been installed.
      DAML Release: v3.4.0-snapshot.20250813.1
      
      Canton requires Java 11 or later. You may need to set JAVA_HOME:
        export JAVA_HOME=$(/usr/libexec/java_home -v 11)
      
      Or if using Homebrew's OpenJDK:
        export JAVA_HOME="#{Formula["openjdk@17"].opt_prefix}/libexec/openjdk.jdk/Contents/Home"
      
      Configuration files are available at:
        #{prefix}/config/
      
      Examples are available at:
        #{prefix}/examples/
      
      Documentation are available at:
        #{prefix}/docs/
        
      Version info saved at:
        #{prefix}/VERSION_INFO.txt
        
      NOTE: This is a specific version installation. To get the latest pre-release, use:
        brew install canton
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
