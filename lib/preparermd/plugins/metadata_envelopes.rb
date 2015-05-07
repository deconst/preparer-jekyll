require 'json'
require 'jekyll'
require 'faraday'

module PreparerMD

  # Generator plugin to construct JSON metadata envelopes.
  #
  class JSONGenerator < Jekyll::Generator

    def generate(site)
      if PreparerMD.config.should_submit?
        @conn = Faraday.new(url: PreparerMD.config.content_store_url) do |conn|
          conn.response :raise_error

          conn.adapter Faraday.default_adapter
        end
      end

      site.posts.each do |post|
        render_json(post, site)
      end

      site.pages.each do |page|
        render_json(page, site)
      end
    end

    def render_json(page, site)
      layout = page.data["deconst-layout"] || page.data["layout"]

      page.data["layout"] = nil
      page.render({}, site.site_payload)

      output = page.to_liquid

      envelope = {
        title: output["title"],
        body: output["content"],
        layout_key: layout,
      }

      if PreparerMD.config.should_submit?
        base = PreparerMD.config.content_id_base

        content_id = File.join(base, Jekyll::URL.unescape_path(page.url))
        content_id.gsub! %r{/index\.html\Z}, ""

        @conn.put do |req|
          req.url "/content/#{CGI.escape content_id}"
          req.headers['Content-Type'] = 'application/json'
          req.body = envelope.to_json
        end

        puts "Submitted envelope: [#{content_id}]"
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
