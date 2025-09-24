require "json"
require "net/http"
require "uri"

class Canton < Formula
  desc "Blockchain protocol implementation from Digital Asset (latest pre-release)"
  homepage "https://www.canton.network/"

  # Load the version manifest from JSON file
  def self.load_manifest
    manifest_path = File.expand_path("../../canton-versions.json", __FILE__)
    if File.exist?(manifest_path)
      JSON.parse(File.read(manifest_path))
    else
      nil
    end
  rescue => e
    nil
  end

  # Get the latest version from the manifest
  def self.latest_from_manifest
    manifest = load_manifest
    return nil unless manifest && manifest["versions"]

    # Sort versions by published_at date to get the actual latest
    sorted_versions = manifest["versions"].sort_by do |_tag, info|
      Time.parse(info["published_at"])
    end.reverse

    latest_entry = sorted_versions.first
    return nil unless latest_entry

    tag = latest_entry[0]
    info = latest_entry[1]

    {
      daml_tag: tag,
      canton_version: info["canton_version"],
      download_url: info["download_url"],
      sha256: info["sha256"],
      is_prerelease: info["is_prerelease"]
    }
  end

  # Dynamically fetch the latest pre-release
  def self.fetch_latest_prerelease
    # Try to fetch from GitHub API
    uri = URI("https://api.github.com/repos/digital-asset/daml/releases")
    response = Net::HTTP.get_response(uri)

    unless response.code == "200"
      raise "Failed to fetch releases: #{response.code}"
    end

    releases = JSON.parse(response.body)

    # Find the latest pre-release with Canton assets
    prerelease = releases.find do |release|
      release["prerelease"] && release["assets"]&.any? do |asset|
        asset["name"].include?("canton-open-source") && asset["name"].end_with?(".tar.gz")
      end
    end

    unless prerelease
      # Fall back to latest release if no pre-release found
      prerelease = releases.find do |release|
        release["assets"]&.any? do |asset|
          asset["name"].include?("canton-open-source") && asset["name"].end_with?(".tar.gz")
        end
      end
    end

    unless prerelease
      raise "No Canton releases found"
    end

    canton_asset = prerelease["assets"].find do |asset|
      asset["name"].include?("canton-open-source") && asset["name"].end_with?(".tar.gz")
    end

    canton_version = canton_asset["name"].gsub(/canton-open-source-(.+)\.tar\.gz/, '\1')
    tag = prerelease["tag_name"]

    release_info = {
      daml_tag: tag,
      canton_version: canton_version,
      download_url: canton_asset["browser_download_url"],
      is_prerelease: prerelease["prerelease"]
    }

    # Look up SHA256 from manifest
    manifest = load_manifest
    if manifest && manifest["versions"] && manifest["versions"][tag]
      release_info[:sha256] = manifest["versions"][tag]["sha256"]
    end

    release_info
  rescue => e
    # Fallback to manifest if API fails
    manifest_fallback = latest_from_manifest
    if manifest_fallback
      manifest_fallback
    else
      # Last resort hardcoded fallback (should be kept in sync via updates)
      # Auto-updated by GitHub Actions - DO NOT MODIFY MANUALLY
      {
        daml_tag: "v3.4.0-snapshot.20250918.0",
        canton_version: "3.4.0-snapshot.20250916.16914.0.vab38472a",
        download_url: "https://github.com/digital-asset/daml/releases/download/v3.4.0-snapshot.20250918.0/canton-open-source-3.4.0-snapshot.20250916.16914.0.vab38472a.tar.gz",
        sha256: "e073d9f05040c963e392ff2e19445ca3daa95e3faa57877bd4e08ea6ad74001f",
        is_prerelease: true
      }
    end
  end

  # Fetch latest release info at formula load time
  latest = fetch_latest_prerelease

  url latest[:download_url]
  sha256 latest[:sha256]
  version latest[:daml_tag].gsub(/^v/, "")
  license "Apache-2.0"

  # Java 11+ is required (recommend 17 for best compatibility)
  depends_on "openjdk@17" => :recommended

  def install
    prefix.install Dir["*"]
    
    # Create a version info file for reference
    (prefix/"VERSION_INFO.txt").write <<~EOS
      Canton Version: #{self.class.fetch_latest_prerelease[:canton_version]}
      DAML Tag: #{version}
      Pre-release: #{self.class.fetch_latest_prerelease[:is_prerelease] ? "Yes" : "No"}
      Installed: #{Time.now}
    EOS
  end

  def caveats
    release_info = self.class.fetch_latest_prerelease
    release_type = release_info[:is_prerelease] ? "pre-release" : "stable"

    <<~EOS
      Canton #{release_info[:canton_version]} (#{release_type}) has been installed.
      DAML Release Tag: #{release_info[:daml_tag]}

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
