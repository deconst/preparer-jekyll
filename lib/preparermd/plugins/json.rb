puts "This file was required"

module PreparerMD

  # Generator plugin to construct JSON metadata envelopes.
  #
  class JSONGenerator < Jekyll::Generator

    def generate(site)
      puts "Hooray, I ran"
    end

  end

end

# Disable everyone else's generator plugins because screw those things.
#
module Jekyll
  class Generator < Plugin
    def self.descendants
      [PreparerMD::JSONGenerator]
    end
  end
end
