require "jekyll"
require "jekyll-assets"
require "bundler"
require "bundler/cli"
require "bundler/cli/install"

require "preparermd/version"
require "preparermd/config"
require "preparermd/overrides/jekyll"
require "preparermd/overrides/environment"
require "preparermd/plugins/metadata_envelopes"

module PreparerMD

  # Primary entry point for the site build. Execute a Jekyll build with customized options.
  #
  def self.build(source = './')
    @config = Config.new
    @config.validate

    if File.exist?("Gemfile")
      puts "Installing dependencies from the Jekyll environment."
      Bundler::CLI::Install.new({}).run
    end

    puts "Building and submitting content."
    Jekyll::Commands::Build.process({source: source})
  end

  # Access the preparer's configuration.
  #
  def self.config
    @config
  end

end
