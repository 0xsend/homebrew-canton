#!/usr/bin/env ruby
# Helper script to get Canton release information for Homebrew formula
# This script is called by the canton.rb formula when CANTON_VERSION is set

require 'json'
require 'net/http'
require 'uri'

daml_tag = ARGV[0]

unless daml_tag
  puts JSON.generate({ error: "Usage: #{$0} <daml_tag>" })
  exit 1
end

begin
  # Fetch release info from GitHub API
  uri = URI("https://api.github.com/repos/digital-asset/daml/releases")
  response = Net::HTTP.get_response(uri)
  
  unless response.code == '200'
    puts JSON.generate({ error: "Failed to fetch releases: #{response.code}" })
    exit 1
  end
  
  releases = JSON.parse(response.body)
  
  # Find the specific release
  release = releases.find { |r| r['tag_name'] == daml_tag }
  
  unless release
    puts JSON.generate({ error: "DAML release #{daml_tag} not found" })
    exit 1
  end
  
  # Find Canton asset in the release
  canton_asset = release['assets']&.find do |asset|
    asset['name'].include?('canton-open-source') && asset['name'].end_with?('.tar.gz')
  end
  
  unless canton_asset
    puts JSON.generate({ error: "Canton asset not found in DAML release #{daml_tag}" })
    exit 1
  end
  
  # Extract Canton version from asset name
  canton_version = canton_asset['name'].gsub(/canton-open-source-(.+)\.tar\.gz/, '\1')
  
  # Output the release info as JSON
  puts JSON.generate({
    daml_tag: daml_tag,
    canton_version: canton_version,
    download_url: canton_asset['browser_download_url'],
    asset_name: canton_asset['name']
  })
  
rescue => e
  puts JSON.generate({ error: "Error: #{e.message}" })
  exit 1
end