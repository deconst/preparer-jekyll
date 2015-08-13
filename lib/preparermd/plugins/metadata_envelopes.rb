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
      layout = page.data["deconst_layout"] || page.data["layout"]

      global_tags = site.config["deconst_tags"] || []
      global_post_tags = site.config["deconst_post_tags"] || []
      global_page_tags = site.config["deconst_page_tags"] || []

      page.data["layout"] = nil
      page.render({}, site.site_payload)

      output = page.to_liquid

      envelope = {
        title: output["title"],
        body: output["content"],
        categories: output["categories"] || [],
        meta: page.data.dup
      }

      tags = Set.new(output["tags"] || [])

      tags.merge(global_tags)
      tags.merge(case page
        when Jekyll::Page
          global_page_tags
        when Jekyll::Post
          global_post_tags
        else
          []
        end)

      envelope["tags"] = tags.to_a

      attr_plain = ->(from, to = from) { envelope[to] = output[from] if output[from] }
      attr_date = ->(from, to = from) { envelope[to] = output[from].rfc2822 if output[from] }
      attr_page = ->(from, to = from) do
        linked_page = output[from]
        envelope[to] = { url: linked_page.url, title: linked_page.title } if linked_page
      end

      attr_plain.call "content_type"
      attr_plain.call "author"
      attr_plain.call "bio"
      attr_date.call "date", "publish_date"
      attr_page.call "next"
      attr_page.call "previous"
      attr_plain.call "queries"

      # Discus integration attributes
      page_disqus = output["disqus"]
      if page_disqus || site.config["disqus_short_name"]
        short_name = site.config["disqus_short_name"]
        mode = site.config["disqus_default_mode"] || "embed"

        if page_disqus
          short_name = page_disqus["short_name"] if page_disqus["short_name"]
          mode = page_disqus["mode"] if page_disqus["mode"]
        end

        envelope["disqus"] = {
          include: true,
          short_name: short_name,
          embed: mode == "embed"
        }
      end

      if PreparerMD.config.should_submit?
        base = PreparerMD.config.content_id_base
        auth = "deconst apikey=\"#{PreparerMD.config.content_store_apikey}\""

        content_id = File.join(base, Jekyll::URL.unescape_path(page.url))
        content_id.gsub! %r{/index\.html\Z}, ""

        print "Submitting envelope: [#{content_id}] .. "
        $stdout.flush

        resp = @conn.put do |req|
          req.url "/content/#{CGI.escape content_id}"
          req.headers['Content-Type'] = 'application/json'
          req.headers['Authorization'] = auth
          req.body = envelope.to_json
        end

        puts "ok"
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
