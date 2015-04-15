# Monkey patches for Jekyll itself.

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

    def cleanup
    end
  end

end
