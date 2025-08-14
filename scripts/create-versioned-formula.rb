#!/usr/bin/env ruby
# Script to create a versioned Canton formula for a specific DAML release
# Usage: ./create-versioned-formula.rb <daml-tag>
# Example: ./create-versioned-formula.rb v3.4.0-snapshot.20250813.1

require 'json'
require 'net/http'
require 'uri'
require 'digest'
require 'fileutils'

def fetch_release_info(daml_tag)
  # Remove 'v' prefix if present for API search
  tag_with_v = daml_tag.start_with?('v') ? daml_tag : "v#{daml_tag}"
  
  uri = URI("https://api.github.com/repos/digital-asset/daml/releases/tags/#{tag_with_v}")
  response = Net::HTTP.get_response(uri)
  
  if response.code == '404'
    # Try fetching all releases if specific tag not found
    uri = URI("https://api.github.com/repos/digital-asset/daml/releases")
    response = Net::HTTP.get_response(uri)
    
    unless response.code == '200'
      raise "Failed to fetch releases: #{response.code}"
    end
    
    releases = JSON.parse(response.body)
    release = releases.find { |r| r['tag_name'] == tag_with_v }
    
    unless release
      raise "DAML release #{tag_with_v} not found"
    end
  elsif response.code == '200'
    release = JSON.parse(response.body)
  else
    raise "Failed to fetch release #{tag_with_v}: #{response.code}"
  end
  
  canton_asset = release['assets']&.find do |asset|
    asset['name'].include?('canton-open-source') && asset['name'].end_with?('.tar.gz')
  end
  
  unless canton_asset
    raise "Canton asset not found in DAML release #{tag_with_v}"
  end
  
  canton_version = canton_asset['name'].gsub(/canton-open-source-(.+)\.tar\.gz/, '\1')
  
  {
    daml_tag: tag_with_v,
    canton_version: canton_version,
    download_url: canton_asset['browser_download_url'],
    is_prerelease: release['prerelease']
  }
end

def calculate_sha256(url)
  puts "Calculating SHA256 for #{url}..."
  
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = 300 # 5 minutes timeout for large files
  
  request = Net::HTTP::Get.new(uri)
  response = http.request(request)
  
  # Follow redirects
  while response.code == '302' || response.code == '301'
    uri = URI(response['location'])
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 300
    request = Net::HTTP::Get.new(uri)
    response = http.request(request)
  end
  
  unless response.code == '200'
    raise "Failed to download file: #{response.code}"
  end
  
  sha256 = Digest::SHA256.hexdigest(response.body)
  puts "SHA256: #{sha256}"
  sha256
end

def create_formula(info, sha256)
  # Create formula class name from DAML tag
  # Remove 'v' prefix and replace dots and dashes with underscores
  clean_version = info[:daml_tag].gsub(/^v/, '').gsub(/[.-]/, '_')
  class_name = "CantonAT#{clean_version.gsub(/_/, '').capitalize}"
  
  # Simplify class name for better readability
  # e.g., v3.4.0-snapshot.20250813.1 -> CantonAT340Snapshot202508131
  class_name = "CantonAT" + info[:daml_tag]
    .gsub(/^v/, '')
    .gsub(/[^a-zA-Z0-9]/, '')
    .capitalize
  
  formula_content = <<~RUBY
    class #{class_name} < Formula
      desc "Blockchain protocol implementation from Digital Asset (#{info[:daml_tag]})"
      homepage "https://www.canton.network/"
      
      url "#{info[:download_url]}"
      sha256 "#{sha256}"
      version "#{info[:daml_tag].gsub(/^v/, '')}"
      license "Apache-2.0"
      
      # Java 11+ is required (recommend 17 for best compatibility)
      depends_on "openjdk@17" => :recommended
      
      # Conflicts with main canton formula
      conflicts_with "canton", because: "both install the same binaries"
      
      def install
        prefix.install Dir["*"]
        
        # Create a version info file for reference
        (prefix/"VERSION_INFO.txt").write <<~EOS
          Canton Version: #{info[:canton_version]}
          DAML Tag: #{info[:daml_tag]}
          Pre-release: #{info[:is_prerelease] ? "Yes" : "No"}
          Installed: \#{Time.now}
        EOS
      end
      
      def caveats
        release_type = #{info[:is_prerelease]} ? "pre-release" : "stable"
        
        <<~EOS
          Canton #{info[:canton_version]} (\#{release_type}) has been installed.
          DAML Release: #{info[:daml_tag]}
          
          Canton requires Java 11 or later. You may need to set JAVA_HOME:
            export JAVA_HOME=$(/usr/libexec/java_home -v 11)
          
          Or if using Homebrew's OpenJDK:
            export JAVA_HOME="\#{Formula["openjdk@17"].opt_prefix}/libexec/openjdk.jdk/Contents/Home"
          
          Configuration files are available at:
            \#{prefix}/config/
          
          Examples are available at:
            \#{prefix}/examples/
          
          Documentation are available at:
            \#{prefix}/docs/
            
          Version info saved at:
            \#{prefix}/VERSION_INFO.txt
            
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
        assert_match(/version "(1\\.)?(8|9|11|17|21)/, java_version)
        
        # Test that Canton can show help (basic functionality test)
        output = shell_output("\#{bin}/canton --help 2>&1")
        assert_match(/Canton/, output)
        
        # Check version info file was created
        assert_path_exists prefix/"VERSION_INFO.txt"
      end
    end
  RUBY
  
  # Create formula filename using DAML tag format
  # e.g., canton@3.4.0-snapshot.20250813.1.rb
  version_suffix = info[:daml_tag].gsub(/^v/, '')
  formula_filename = "canton@#{version_suffix}.rb"
  
  {
    filename: formula_filename,
    content: formula_content,
    class_name: class_name
  }
end

def check_manifest_for_sha256(daml_tag)
  manifest_path = File.join(File.dirname(__FILE__), '..', 'canton-versions.json')
  return nil unless File.exist?(manifest_path)
  
  begin
    manifest = JSON.parse(File.read(manifest_path))
    tag_with_v = daml_tag.start_with?('v') ? daml_tag : "v#{daml_tag}"
    
    if manifest['versions'] && manifest['versions'][tag_with_v]
      return manifest['versions'][tag_with_v]['sha256']
    end
  rescue => e
    puts "Warning: Could not read manifest: #{e.message}"
  end
  
  nil
end

def save_to_manifest(info, sha256)
  manifest_path = File.join(File.dirname(__FILE__), '..', 'canton-versions.json')
  
  manifest = if File.exist?(manifest_path)
    JSON.parse(File.read(manifest_path))
  else
    {
      'updated_at' => Time.now.iso8601,
      'versions' => {}
    }
  end
  
  manifest['versions'][info[:daml_tag]] = {
    'canton_version' => info[:canton_version],
    'download_url' => info[:download_url],
    'sha256' => sha256,
    'is_prerelease' => info[:is_prerelease],
    'published_at' => Time.now.iso8601
  }
  
  manifest['updated_at'] = Time.now.iso8601
  
  File.write(manifest_path, JSON.pretty_generate(manifest))
  puts "Updated manifest with #{info[:daml_tag]}"
end

# Main execution
if ARGV.length != 1
  puts "Usage: #{$0} <daml-tag>"
  puts "Example: #{$0} 3.4.0-snapshot.20250813.1"
  puts "         #{$0} v3.4.0-snapshot.20250813.1"
  exit 1
end

daml_tag = ARGV[0]

begin
  puts "Fetching release info for #{daml_tag}..."
  info = fetch_release_info(daml_tag)
  
  puts "Found Canton #{info[:canton_version]}"
  puts "Release type: #{info[:is_prerelease] ? 'Pre-release' : 'Stable'}"
  
  # Check manifest first for SHA256
  sha256 = check_manifest_for_sha256(daml_tag)
  
  if sha256
    puts "Using cached SHA256 from manifest: #{sha256}"
  else
    puts "Calculating SHA256..."
    sha256 = calculate_sha256(info[:download_url])
    
    # Save to manifest for future use
    save_to_manifest(info, sha256)
  end
  
  formula = create_formula(info, sha256)
  
  # Ensure Formula directory exists
  formula_dir = File.join(File.dirname(__FILE__), '..', 'Formula')
  FileUtils.mkdir_p(formula_dir)
  
  # Write formula file
  formula_path = File.join(formula_dir, formula[:filename])
  File.write(formula_path, formula[:content])
  
  puts "\n✅ Created formula: #{formula_path}"
  puts "   Class name: #{formula[:class_name]}"
  puts "\nTo install this version:"
  puts "  brew install ./Formula/#{formula[:filename]}"
  puts "\nOr if you've tapped the repository:"
  puts "  brew tap 0xsend/homebrew-canton"
  puts "  brew install canton@#{daml_tag.gsub(/^v/, '')}"
  
rescue => e
  puts "❌ Error: #{e.message}"
  exit 1
end