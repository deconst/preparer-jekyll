require 'json'
require 'jekyll'
require 'faraday'

module PreparerMD

  # Generator plugin to construct JSON metadata envelopes.
  #
  class JSONGenerator < Jekyll::Generator

    def generate(site)
      if PreparerMD.config.should_submit?
        @conn = Faraday.new(url: PreparerMD.config.content_store_url)
      end

      site.posts.each do |post|
        render_json(post, site)
      end

      site.pages.each do |page|
        render_json(page, site)
      end
    end

    def render_json(page, site)
      page.data["layout"] = nil
      page.render({}, site.site_payload)

      output = page.to_liquid

      envelope = {
        title: output["title"],
        body: output["content"]
      }

      if PreparerMD.config.should_submit?
        base = PreparerMD.config.content_id_base

        content_id = File.join(base, Jekyll::URL.unescape_path(page.url))
        content_id.gsub! %r{/index\.html\Z}, ""

        puts "Submitting envelope: [#{content_id}]"

        @conn.put do |req|
          req.url "/content/#{CGI.escape content_id}"
          req.headers['Content-Type'] = 'application/json'
          req.body = envelope.to_json
        end
      else
        path = page.destination(site.dest)

        if path == File.join(site.dest, "index.html")
          path = File.join(site.dest, "index.json")
        else
          path.gsub! %r{/index\.html\Z}, ".json"
        end

        puts "Writing envelope to [#{path}]"

        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, 'w') { |f| f.write(envelope.to_json) }
      end
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
