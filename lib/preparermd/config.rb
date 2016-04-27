require 'json'

module PreparerMD

  # Configuration values and credentials read from the process' environment.
  #
  class Config
    attr_reader :content_root, :envelope_dir, :asset_dir, :verbose
    attr_reader :content_id_base, :jekyll_document, :github_url, :github_branch, :meta


    # Create a new configuration populated with values from the environment.
    #
    def initialize
      @content_root = ENV.fetch('CONTENT_ROOT', '')
      @envelope_dir = ENV.fetch('ENVELOPE_DIR', File.join(Dir.pwd, '_site', 'deconst-envelopes'))
      @asset_dir = ENV.fetch('ASSET_DIR', File.join(Dir.pwd, '_site', 'deconst-assets'))
      @verbose = ENV.fetch('VERBOSE', '') != ''

      @content_id_base = ENV.fetch('CONTENT_ID_BASE', '').gsub(%r{/\Z}, '')
      @jekyll_document = ENV.fetch('JEKYLL_DOCUMENT', '')
    end

    def has_content_root?
      ! @content_root.empty?
    end

    def load_from(f)
      jsondata = JSON.parse(f)

      if jsondata["contentIDBase"]
        if @content_id_base == ""
          @content_id_base = jsondata["contentIDBase"].gsub(%r{/\Z}, '')
        elsif @content_id_base != jsondata["contentIDBase"].gsub(%r{/\Z}, '')
          $stderr.puts "Using environment variable CONTENT_ID_BASE=[#{@content_id_base}] " \
            "instead of _deconst.json setting [#{jsondata["contentIDBase"]}]."
        end
      end

      if jsondata["meta"]
        @meta = jsondata["meta"]
      else
        @meta = {}
      end

      if jsondata["githubUrl"]
        @github_url = jsondata["githubUrl"]

        @meta["github_issues_url"] = [@github_url, '/issues'].map { |s|
          s.gsub(/\/$/, '').gsub(/^\//, '')
        }.join('/')
      end

      if jsondata["githubBranch"]
        @github_branch = jsondata["githubBranch"]
      else
        @github_branch = "master"
      end
    end

    # Determine and report (to stderr) whether or not we have enough information to prepare.
    #
    def validate
      reasons = []

      if @content_id_base.empty?
        reasons << "CONTENT_ID_BASE is missing. It should be the common prefix used to generate " \
          "IDs for content within this repository."
      end

      unless reasons.empty?
        $stderr.puts "Unable to prepare content because:"
        $stderr.puts
        $stderr.puts reasons.map { |r| " * #{r}\n"}.join
        $stderr.puts

        @should_submit = false
      end
    end
  end

end
