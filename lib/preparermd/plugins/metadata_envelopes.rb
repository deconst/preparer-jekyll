require 'json'
require 'uri'
require 'jekyll'
require 'faraday'

module PreparerMD

  # Generator plugin to construct JSON metadata envelopes.
  #
  class JSONGenerator < Jekyll::Generator

    def generate(site)
      if PreparerMD.config.should_submit?
        opts = {url: PreparerMD.config.content_store_url}
        opts[:ssl] = {verify: false} if !PreparerMD.config.content_store_tls_verify

        @conn = Faraday.new(opts) do |conn|
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
      global_categories = site.config["deconst_categories"] || []
      global_unsearchable = site.config["deconst_default_unsearchable"]

      attr_plain = ->(document, from, to = from) { envelope[to] = document[from] unless document[from].nil? }
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
          body: liquid["content"]
        }

        attr_plain.call liquid, "content_type"
        attr_plain.call liquid, "author"
        attr_plain.call liquid, "bio"
        attr_date.call liquid, "date", "publish_date"
        attr_page.call liquid, "next"
        attr_page.call liquid, "previous"
        attr_plain.call liquid, "queries"
        attr_plain.call liquid, "unsearchable"

        categories = Set.new(liquid["categories"] || [])
        categories.merge(liquid["deconst_categories"] || [])

        tags = Set.new(liquid["tags"] || [])
        page_disqus = liquid["disqus"]
      else
        envelope = {
          title: document.data['title'],
          body: Jekyll::Renderer.new(site, document).run,
          categories: document.data['categories'] || []
        }

        attr_plain.call document.data, "content_type"
        attr_plain.call document.data, "author"
        attr_plain.call document.data, "bio"
        attr_date.call document.data, "date", "publish_date"
        attr_page.call document.data, "next"
        attr_page.call document.data, "previous"
        attr_plain.call document.data, "queries"
        attr_plain.call document.data, "unsearchable"

        categories = Set.new(document.data['categories'] || [])
        categories.merge(document.data['deconst_categories'] || [])

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
      categories.merge(global_categories)

      unless global_unsearchable.nil? || envelope.has_key?("unsearchable")
        envelope["unsearchable"] = global_unsearchable
      end

      envelope["tags"] = tags.to_a.sort
      envelope["categories"] = categories.to_a.sort

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

      meta = PreparerMD.config.meta
      meta = meta.merge(document.data.dup)

      if PreparerMD.config.github_url
        # Hope Github doesn't change this URL
        edit_url_segments = [
          PreparerMD.config.github_url,
          "edit",
          PreparerMD.config.github_branch,
          document.relative_path
        ]

        meta["github_edit_url"] = edit_url_segments.map { |s|
          s.gsub(/\/$/, '').gsub(/^\//, '')
        }.join('/')
      end

      envelope["meta"] = meta

      # Derive asset offsets from the rendered envelope
      asset_offsets = Hash.new { |h, k| h[k] = [] }
      adjustment = 0
      envelope[:body].gsub! /__deconst-asset:([^_]+)__/ do
        md = Regexp.last_match
        asset_offsets[URI.unescape md[1]] << md.begin(0) + adjustment
        adjustment -= (md[0].length - 1)
        'X'
      end
      envelope[:asset_offsets] = asset_offsets unless asset_offsets.empty?

      envelope
    end

    def render_json(document, site)
      if PreparerMD.config.jekyll_document != '' and PreparerMD.config.jekyll_document != Jekyll::URL.unescape_path(document.url)
        return
      end

      envelope = envelope_from_document(document, site)

      base = PreparerMD.config.content_id_base
      content_id = File.join(base, Jekyll::URL.unescape_path(document.url))
      content_id.gsub! %r{/*(index)?(\.html|\.json)?\Z}, ""

      if PreparerMD.config.should_submit?
        auth = "deconst apikey=\"#{PreparerMD.config.content_store_apikey}\""

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
        path = File.join(site.dest, CGI.escape(content_id) + '.json')

        print "Writing envelope: [#{path}] .. "
        $stdout.flush

        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, 'w') { |f| f.write(envelope.to_json) }
        puts "ok"
      end
    end

  end

end
