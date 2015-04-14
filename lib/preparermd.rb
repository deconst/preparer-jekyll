require "jekyll"

require "preparermd/version"
require "preparermd/plugins/json"

module PreparerMD

  # Primary entry point for the site build. Execute a Jekyll build with customized options.
  #
  def self.build
    opts = {}

    Jekyll::Commands::Build.process(opts)
  end

end
