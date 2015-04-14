require 'json'
require 'jekyll'

module PreparerMD

  # Generator plugin to construct JSON metadata envelopes.
  #
  class JSONGenerator < Jekyll::Generator

    def generate(site)
      site.posts.each do |post|
        render_json(post, site)
      end

      site.pages.each do |page|
        render_json(page, site)
      end
    end

    def render_json(page, site)
      path = page.destination(site.dest)

      return unless path =~ /\/index\.html$/

      path["/index.html"] = ".json"

      page.data["layout"] = nil
      page.render({}, site.site_payload)

      output = page.to_liquid
      output["next"] = output["next"].id if output["next"]
      output["previous"] = output["previous"].id if output["previous"]

      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') { |f| f.write(output.to_json) }
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

    def cleanup
    end
  end

end
