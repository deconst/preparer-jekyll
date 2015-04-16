require "jekyll"
require "jekyll-assets"

require "preparermd/version"
require "preparermd/config"
require "preparermd/overrides/jekyll"
require "preparermd/overrides/environment"
require "preparermd/plugins/metadata_envelopes"

module PreparerMD

  # Primary entry point for the site build. Execute a Jekyll build with customized options.
  #
  def self.build
    @config = Config.new
    @config.validate

    Jekyll::Commands::Build.process({})
  end

  # Access the preparer's configuration.
  #
  def self.config
    @config
  end

end
