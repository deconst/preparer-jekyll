require 'json'
require 'uri'

require 'faraday'
require 'sprockets'
require 'jekyll/assets_plugin/environment'

# Module to be mixed in to each uploaded Asset to ensure that the correct URLs are generated.
#
module PreparerMD
  module AssetPatch
    attr_accessor :asset_render_url
  end
end

# Custom Index subclass that uploads each built asset to the content service as it is discovered.
#
class Index < Sprockets::Index
  def initialize(*args)
    super

    opts = {url: PreparerMD.config.content_store_url}
    opts[:ssl] = {verify: false} if !PreparerMD.config.content_store_tls_verify
    @conn = Faraday.new(opts) do |conn|
      conn.request :retry, max: 3, methods: [:post]
      conn.request :multipart
      conn.response :raise_error

      conn.adapter Faraday.default_adapter
    end
  end

  def build_asset(path, pathname, options)
    auth = "deconst apikey=\"#{PreparerMD.config.content_store_apikey}\""

    if PreparerMD.config.should_submit?
      super.tap do |asset|
        asset.pathname.open do |f|
          print "Submitting content asset: [#{asset.logical_path}] .. "
          $stdout.flush

          response = @conn.post do |req|
            req.url '/assets'
            req.headers['Authorization'] = auth
            req.body = {
              asset.logical_path => Faraday::UploadIO.new(f, asset.content_type, asset.logical_path)
            }

            req.options.timeout = 120
            req.options.open_timeout = 60
          end

          asset_url = JSON.parse(response.body)[File.basename asset.logical_path]

          asset.extend PreparerMD::AssetPatch
          asset.asset_render_url = asset_url

          puts "ok"
        end
      end
    else
      super.tap do |asset|
        dest = File.join(PreparerMD.config.asset_dir, asset.logical_path)
        print "Copying content asset: [#{asset.pathname}] .. "
        $stdout.flush

        FileUtils.mkdir_p File.dirname(dest)
        FileUtils.cp asset.pathname.to_s, dest

        asset.extend PreparerMD::AssetPatch
        asset.asset_render_url = "__deconst-asset:#{URI.escape asset.logical_path, '%_'}__"

        puts "ok"
      end
    end
  end
end

# Custom Sprockets Environment subclass that uses our injected Index subclass.
#
class Environment < Jekyll::AssetsPlugin::Environment
  def index
    Index.new(self)
  end
end

# Monkey-patch the Jekyll Assets plugin AssetPath class to use the #asset_render_url
#
module Jekyll
  module AssetsPlugin

    class AssetPath
      alias_method :orig_to_s, :to_s
      def to_s
        @asset.respond_to?(:asset_render_url) ? @asset.asset_render_url : orig_to_s
      end
    end

  end
end
