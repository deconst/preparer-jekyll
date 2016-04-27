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
  def build_asset(path, pathname, options)
    super.tap do |asset|
      dest = File.join(PreparerMD.config.asset_dir, asset.logical_path)

      if PreparerMD.config.verbose
        print "Copying content asset: [#{asset.pathname}] .. "
        $stdout.flush
      end

      FileUtils.mkdir_p File.dirname(dest)
      FileUtils.cp asset.pathname.to_s, dest

      asset.extend PreparerMD::AssetPatch
      asset.asset_render_url = "__deconst-asset:#{URI.escape asset.logical_path, '%_&"<>'}__"

      puts "ok" if PreparerMD.config.verbose
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
