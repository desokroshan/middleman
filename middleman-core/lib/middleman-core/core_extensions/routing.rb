# Routing extension
module Middleman
  module CoreExtensions
    class Routing < Extension
      # This should always run late, but not as late as :directory_indexes,
      # so it can add metadata to any pages generated by other extensions
      self.resource_list_manipulator_priority = 80

      def initialize(app, options_hash={}, &block)
        super

        @page_configs = []
      end

      def before_configuration
        app.add_to_config_context :page, &method(:page)
      end

      def manipulate_resource_list(resources)
        resources.each do |resource|
          @page_configs.each do |matcher, metadata|
            resource.add_metadata(metadata) if Middleman::Util.path_match(matcher, "/#{resource.path}")
          end
        end
      end

      # The page method allows options to be set for a given source path, regex, or glob.
      # Options that may be set include layout, locals, proxy, andx ignore.
      #
      # @example
      #   page '/about.html', layout: false
      # @example
      #   page '/index.html', layout: :homepage_layout
      # @example
      #   page '/foo.html', locals: { foo: 'bar' }
      #
      # @param [String, Regexp] path A source path, or a Regexp/glob that can match multiple resources.
      # @params [Hash] opts Options to apply to all matching resources. Undocumented options are passed on as page metadata to be used by extensions.
      # @option opts [Symbol, Boolean, String] layout The layout name to use (e.g. `:article`) or `false` to disable layout.
      # @option opts [Boolean] directory_indexes Whether or not the `:directory_indexes` extension applies to these paths.
      # @option opts [Hash] locals Local variables for the template. These will be available when the template renders.
      # @option opts [Hash] data Extra metadata to add to the page. This is the same as frontmatter, though frontmatter will take precedence over metadata defined here. Available via {Resource#data}.
      # @return [void]
      def page(path, opts={})
        options = opts.dup

        # Default layout
        metadata = {
          options: options,
          locals: options.delete(:locals) || {},
          page: options.delete(:data) || {}
        }

        if path.is_a?(String) && !path.include?('*')
          # Normalize path
          path = Middleman::Util.normalize_path(path)
          if path.end_with?('/') || File.directory?(File.join(@app.source_dir, path))
            path = File.join(path, @app.config[:index_file])
          end
        end

        path = '/' + Util.strip_leading_slash(path) if path.is_a?(String)

        @page_configs << [path, metadata]
      end
    end
  end
end
