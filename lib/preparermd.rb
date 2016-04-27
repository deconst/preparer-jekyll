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
  def self.build(source = nil, destination = nil)
    @config = Config.new

    if @config.has_content_root?
      if ! source.nil? && source != @config.content_root
        puts "Warning: Overriding CONTENT_ROOT [#{@config.content_root}] with argument [#{source}]."
      else
        Dir.chdir @config.content_root
        source = @config.content_root
      end
    else
      source ||= Dir.pwd
    end
    destination ||= @config.envelope_dir

    config_path = File.join(source, "_deconst.json")
    if File.exist?(config_path)
      File.open(config_path, "r") { |cf| @config.load_from(cf.read) }
    end

    @config.validate

    if File.exist?("Gemfile")
      puts "Installing dependencies from the Jekyll environment."
      Bundler::CLI::Install.new({}).run
    end

    puts "Preparing content."
    Jekyll::Commands::Build.process({source: source, destination: destination})
  end

  # Access the preparer's configuration.
  #
  def self.config
    @config
  end

end
