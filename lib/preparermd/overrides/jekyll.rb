# Monkey patches for Jekyll itself.

require 'jekyll'

require 'preparermd/overrides/jekyll'

module Jekyll

  # Disable everyone else's generator plugins because screw those things.
  #
  class Generator < Plugin
    def self.descendants
      [PreparerMD::JSONGenerator]
    end
  end

  class Site

    # Hook the Jekyll Assets environment creation to use our own Environment subclass.
    #
    def assets
      @assets ||= Environment.new(self)
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
