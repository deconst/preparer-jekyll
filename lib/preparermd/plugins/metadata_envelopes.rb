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
          conn.request :retry, max: 3, methods: [:put]
          conn.response :raise_error

          conn.adapter Faraday.default_adapter
        end
      end

      site.collections.each do |label, collection|
        collection.docs.each do |document|
          render_json(document, site)
        end
      end

      site.posts.each do |post|
        render_json(post, site)
      end

      site.pages.each do |page|
        render_json(page, site)
      end
    end

    # Assembles a document (page, post, or collection item) into a JSON-ready
    # hash
    #
    # Returns the envelope hash
    def envelope_from_document(document, site)
      # Is this a page/post, or a collection item?
      # This is probably not a conclusive test
      is_post = document.respond_to?('render')
      envelope = {}
      global_tags = site.config["deconst_tags"] || []
      global_post_tags = site.config["deconst_post_tags"] || []
      global_page_tags = site.config["deconst_page_tags"] || []

      attr_plain = ->(document, from, to = from) { envelope[to] = document[from] if document[from] }
      attr_date = ->(document, from, to = from) { envelope[to] = document[from].rfc2822 if document[from] }
      attr_page = ->(document, from, to = from) do
        linked_page = document[from]
        envelope[to] = { url: linked_page.url, title: linked_page.title } if linked_page
      end

      if is_post
        layout = document.data["deconst_layout"] || document.data["layout"]
        document.data["layout"] = nil
        document.render({}, site.site_payload)

        liquid = document.to_liquid

        envelope = {
          title: liquid["title"],
          body: liquid["content"],
          categories: liquid["categories"] || [],
          meta: document.data.dup
        }

        attr_plain.call liquid, "content_type"
        attr_plain.call liquid, "author"
        attr_plain.call liquid, "bio"
        attr_date.call liquid, "date", "publish_date"
        attr_page.call liquid, "next"
        attr_page.call liquid, "previous"
        attr_plain.call liquid, "queries"

        tags = Set.new(liquid["tags"] || [])
        page_disqus = liquid["disqus"]
      else
        envelope = {
          title: document.data['title'],
          body: Jekyll::Renderer.new(site, document).run,
          categories: document.data['categories'] || [],
          meta: document.data.dup
        }

        attr_plain.call document.data, "content_type"
        attr_plain.call document.data, "author"
        attr_plain.call document.data, "bio"
        attr_date.call document.data, "date", "publish_date"
        attr_page.call document.data, "next"
        attr_page.call document.data, "previous"
        attr_plain.call document.data, "queries"

        tags = Set.new(document.data['tags'] || [])
        page_disqus = document.data["disqus"]
      end

      tags.merge(global_tags)
      tags.merge(case document
        when Jekyll::Page
          global_page_tags
        when Jekyll::Post
          global_post_tags
        else
          []
        end)

      envelope["tags"] = tags.to_a

      # Discus integration attributes

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

      return envelope
    end

    def render_json(document, site)
      if PreparerMD.config.jekyll_document != '' and PreparerMD.config.jekyll_document != Jekyll::URL.unescape_path(document.url)
        return 0
      end

      envelope = envelope_from_document(document, site)

      if PreparerMD.config.should_submit?
        base = PreparerMD.config.content_id_base
        auth = "deconst apikey=\"#{PreparerMD.config.content_store_apikey}\""

        content_id = File.join(base, Jekyll::URL.unescape_path(document.url))
        content_id.gsub! %r{/index\.html\Z}, ""

        print "Submitting envelope: [#{content_id}] .. "
        $stdout.flush

        resp = @conn.put do |req|
          req.url "/content/#{CGI.escape content_id}"
          req.headers['Content-Type'] = 'application/json'
          req.headers['Authorization'] = auth
          req.body = envelope.to_json

          req.options.timeout = 120
          req.options.open_timeout = 60
        end

        puts "ok"
      else
        path = document.destination(site.dest)

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
