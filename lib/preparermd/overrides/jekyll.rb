# Monkey patches for Jekyll itself.

require 'jekyll'

require 'preparermd/overrides/jekyll'

module Jekyll

  class Site

    # Hook the Jekyll Assets environment creation to use our own Environment subclass.
    #
    def assets
      @assets ||= Environment.new(self)
    end

    alias :old_setup :setup
    def setup
      old_setup

      # Ensure that the JSONGenerator is absolutely, positively, the last thing that runs, for
      # reals
      self.generators.delete_if { |g| PreparerMD::JSONGenerator === g }
      self.generators << PreparerMD::JSONGenerator.new(self.config)
    end

    # Don't actually render the page because why would we want to do that
    #
    def render
    end

    # No use writing to a filesystem we're never going to look at.
    #
    def write
    end

    # Stop deleting my json files what are you doing
    #
    def cleanup
    end

  end

end
