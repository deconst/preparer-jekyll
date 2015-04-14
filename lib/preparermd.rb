require "preparermd/version"

require "mercenary"
require "jekyll"

module PreparerMD

  # Public: Primary entry point for the site build. Execute a Jekyll build with customized options.
  #
  def self.build
    opts = {}
    Jekyll::Commands::Build.process(opts)
  end

end
