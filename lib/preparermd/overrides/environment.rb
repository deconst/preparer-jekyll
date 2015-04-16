require 'json'

require 'faraday'
require 'sprockets'
require 'jekyll/assets_plugin/environment'

# Module to be mixed in to each uploaded Asset to ensure that the correct URLs are generated.
#
module PreparerMD
  module AssetPatch
    attr_accessor :asset_cdn_url
  end
end

# Custom Index subclass that uploads each built asset to the content service as it is discovered.
#
class Index < Sprockets::Index
  def initialize(*args)
    super

    @conn = Faraday.new(url: PreparerMD.config.content_store_url) do |conn|
      conn.request :multipart
      conn.response :raise_error

      conn.adapter Faraday.default_adapter
    end
  end

  def build_asset(path, pathname, options)
    if PreparerMD.config.should_submit?
      super.tap do |asset|
        asset.pathname.open do |f|
          response = @conn.post '/assets', {
            asset.logical_path => Faraday::UploadIO.new(f, asset.content_type, asset.logical_path)
          }

          asset_url = JSON.parse(response.body)[File.basename asset.logical_path]

          asset.extend PreparerMD::AssetPatch
          asset.asset_cdn_url = asset_url

          puts "Submitted content asset: [#{asset.logical_path}]"
        end
      end
    else
      super
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

# Monkey-patch the Jekyll Assets plugin AssetPath class to use the #asset_cdn_url
#
module Jekyll
  module AssetsPlugin

    class AssetPath
      def to_s
        @asset.instance_of?(PreparerMD::AssetPatch) ? @asset.asset_cdn_url : super
      end
    end

  end
end
