module PreparerMD

  # Configuration values and credentials read from the process' environment.
  #
  class Config
    attr_reader :content_store_url, :content_store_apikey, :content_id_base


    # Create a new configuration populated with values from the environment.
    #
    def initialize
      @content_store_url = ENV.fetch('CONTENT_STORE_URL', '').gsub(%r{/\Z}, '')
      @content_store_apikey = ENV.fetch('CONTENT_STORE_APIKEY', '')
      @content_id_base = ENV.fetch('CONTENT_ID_BASE', '').gsub(%r{/\Z}, '')
    end

    # Determine and report (to stderr) whether or not we have enough information to submit to the
    # content service.
    #
    def validate
      reasons = []

      if @content_store_url.empty?
        reasons << "CONTENT_STORE_URL is missing. It should be the base URL of the content " \
          "storage service."
      end

      if @content_store_apikey.empty?
        reasons << "CONTENT_STORE_APIKEY is missing. It should be a valid API key issued by the " \
          "content service."
      end

      if @content_id_base.empty?
        reasons << "CONTENT_ID_BASE is missing. It should be the common prefix used to generate " \
          "IDs for content within this repository."
      end

      if ENV['TRAVIS_PULL_REQUEST'] != "false"
        reasons << "This looks like a pull request build on Travis."
      end

      if reasons.empty?
        puts "Content will be submitted to the content service."

        @should_submit = true
      else
        $stderr.puts "Not submitting content to the content service because:"
        $stderr.puts
        $stderr.puts reasons.map { |r| " * #{r}\n"}.join
        $stderr.puts

        @should_submit = false
      end
    end

    # Determine whether or not we have enough information to submit to the content service.
    #
    def should_submit?
      raise "#validate must be called first!" if @should_submit.nil?

      @should_submit
    end
  end

end
