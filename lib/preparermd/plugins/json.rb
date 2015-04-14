module PreparerMD

  # Generator plugin to construct JSON metadata envelopes.
  #
  class JSONGenerator < Jekyll::Generator

    def generate(site)
      puts "Hooray, I ran"
    end

  end

end

module Jekyll

  # Disable everyone else's generator plugins because screw those things.
  #
  class Generator < Plugin
    def self.descendants
      [PreparerMD::JSONGenerator]
    end
  end

  # Don't actually render the page because why would we want to do that
  #
  class Site
    def render
    end

    def write
    end
  end

end
