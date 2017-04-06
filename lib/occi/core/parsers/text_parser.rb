module Occi
  module Core
    module Parsers
      # Contains all text-related classes and modules. This
      # module houses functionality transforming various internal
      # instances from basic text-based rendering.
      #
      # @author Boris Parak <parak@cesnet.cz>
      module Text; end
    end
  end
end

# Load class-specific parsing primitives
Dir[File.join(File.dirname(__FILE__), 'text', '*.rb')].each { |file| require file.gsub('.rb', '') }

module Occi
  module Core
    module Parsers
      # Implementes components necessary to parse all required instance types
      # from `text` or `text`-like format.
      #
      # @attr model [Occi::Core::Model, Occi::Infrastructure::Model] model to use as a primary reference point
      # @attr media_type [String] type of content to parse
      #
      # @author Boris Parak <parak@cesnet.cz>
      class TextParser
        include Yell::Loggable
        include Helpers::ArgumentValidator

        # Media type constants
        URI_LIST_TYPES     = %w[text/uri-list].freeze
        HEADERS_TEXT_TYPES = %w[text/occi].freeze
        PLAIN_TEXT_TYPES   = %w[text/plain text/occi+plain].freeze
        OCCI_TEXT_TYPES    = [HEADERS_TEXT_TYPES, PLAIN_TEXT_TYPES].flatten.freeze
        MEDIA_TYPES        = [URI_LIST_TYPES, OCCI_TEXT_TYPES].flatten.freeze

        # Constants for OCCI keys
        KEY_NAME_GROUPS = %w[LOCATION_KEYS CATEGORY_KEYS LINK_KEYS ATTRIBUTE_KEYS].freeze
        LOCATION_KEYS   = %w[X-OCCI-Location X_occi_location X-occi-location Location].freeze
        CATEGORY_KEYS   = %w[Category X-OCCI-Category X_occi_category X-occi-category].freeze
        LINK_KEYS       = %w[Link X-OCCI-Link X_occi_link X-occi-link].freeze
        ATTRIBUTE_KEYS  = %w[X-OCCI-Attribute X_occi_attribute X-occi-attribute].freeze
        OCCI_KEYS       = [LOCATION_KEYS, CATEGORY_KEYS, LINK_KEYS, ATTRIBUTE_KEYS].flatten.freeze

        # Constants for header normalization
        HEADER_HTTP_PREFIX = 'HTTP_'.freeze

        attr_accessor :model, :media_type

        # TODO: docs
        def initialize(args = {})
          pre_initialize(args)
          default_args! args

          @model = args.fetch(:model)
          @media_type = args.fetch(:media_type)

          post_initialize(args)
        end

        # TODO: docs
        def entities(body, headers, expectation); end

        # See `#entities`.
        def resources(body, headers)
          entities body, headers, Occi::Core::Resource
        end

        # See `#entities`.
        def links(body, headers)
          entities body, headers, Occi::Core::Link
        end

        # TODO: docs
        def action_instances(body, headers); end

        # TODO: docs
        def attributes(body, headers); end

        # TODO: docs
        def categories(body, headers, expectation); end

        # See `#categories`.
        def kinds(body, headers)
          categories body, headers, Occi::Core::Kind
        end

        # See `#categories`.
        def mixins(body, headers)
          categories body, headers, Occi::Core::Mixin
        end

        # See `#categories`.
        def actions(body, headers)
          categories body, headers, Occi::Core::Action
        end

        # Checks whether the given media type is supported by this
        # parser instance.
        #
        # @param media_type [String] media type string as provided by the transport protocol
        # @return [TrueClass] if supported
        # @return [FalseClass] if not supported
        def parses?(media_type)
          self.media_type == media_type
        end

        class << self
          # TODO: docs
          def model(body, headers, media_type); end

          # TODO: docs
          def locations(body, headers, media_type); end

          # Returns a list of supported media types for this parser.
          #
          # @return [Array] list of supported media types
          def media_types
            MEDIA_TYPES
          end

          # Checks whether the given media type is supported by this
          # parser.
          #
          # @param media_type [String] media type string as provided by the transport protocol
          # @return [TrueClass] if supported
          # @return [FalseClass] if not supported
          def parses?(media_type)
            media_types.include? media_type
          end

          # Transforms a `String`-like body into a series of independent lines.
          # Note: Multi-line elements are not supported by this parser.
          #
          # @param body [String] multi-line body
          # @return [Array] an array of lines
          def transform_body(body)
            body.respond_to?(:lines) ? body.lines : body.split("\n")
          end

          # Transforms a widely varied content of headers into a unified body-like
          # format for further processing. This method and its helpers should hide
          # differences between `text/occi` and `text/plain` completely.
          #
          # @param headers [Hash] hash with raw header key-value pairs
          # @return [Array] an array of body-like lines
          def transform_headers(headers)
            unify_headers(
              canonize_headers(
                normalize_headers(headers)
              )
            )
          end

          # Normalizes raw headers into a more agreeable form. This process will remove known prefixes
          # as well as blank lines or non-OCCI keys.
          #
          # @param headers [Hash] hash with raw header key-value pairs
          # @return [Hash] a cleaner hash with relevant headers
          def normalize_headers(headers)
            headers = Hash[
              headers.map { |k, v| [k.gsub(HEADER_HTTP_PREFIX, '').capitalize, v] }
            ]                                                 # remove 'HTTP_' prefix in keys
            headers.delete_if { |_k, v| v.blank? }            # remove pairs with empty values
            headers.keep_if { |k, _v| OCCI_KEYS.include?(k) } # drop non-OCCI pairs
            headers
          end

          # Canonizes normalized headers by eliminating naming differences in keys. Input for
          # this method must be already normalized by `normalize_headers`.
          #
          # @param headers [Hash] hash with normalized header key-value pairs
          # @return [Hash] canonized hash with predictable keys
          def canonize_headers(headers)
            validate_header_keys! headers.keys

            canonical = {}
            headers.each_pair do |key, value|
              pref = key_name_groups.detect { |ka| ka.include?(key) }
              canonical[pref] = [canonize_header_value(value)].flatten
            end

            canonical
          end

          # Attempts to canonize value from headers by looking for hidden multi-value lines usually
          # separated by commas.
          #
          # @param value [Object] value to canonize
          # @return [Object] original or canonized value
          def canonize_header_value(value)
            value = value.first if value.is_a?(Array) && value.count == 1 # ary with 1 could be hidden multi-val
            value = value.split(',').map(&:strip) if value.is_a?(String)  # multi-vals can hide as ','-separated String
            value
          end

          # Unifies canonized headers by transforming them into a body-like
          # form. Output of this method should be directly parsable as
          # `text/plain` found in body.
          #
          # @param headers [Hash] hash with canonized header key-value pairs
          # @return [Array] an array of body-like lines
          def unify_headers(headers)
            lines = []
            headers.each_pair do |k, v|
              lines << v.map { |val| "#{k}: #{val}" }
            end
            lines.flatten.sort
          end

          # Checks for use of multiple keys from a single key name groups. See `key_name_groups` for a list
          # of available groups. Mixed key notations will produce an error.
          #
          # @param headers_keys [Array] list of keys to check
          # @raise [Occi::Core::Errors::ParsingError] if mixed key notations detected
          def validate_header_keys!(headers_keys)
            return unless key_name_groups.any? { |elm| (headers_keys & elm).count > 1 }

            raise Occi::Core::Errors::ParsingError,
                  "Headers #{headers_keys.inspect} contain mixed key notations"
          end

          # Returns a list of available key name groups accessible as constants by name on this class.
          #
          # @return [Array] list of available key name groups
          def key_name_groups
            KEY_NAME_GROUPS.map { |kn| const_get kn }
          end
        end

        protected

        # :nodoc:
        def sufficient_args!(args)
          %i[model media_type].each do |attr|
            unless args[attr]
              raise Occi::Core::Errors::MandatoryArgumentError, "#{attr} is a mandatory " \
                    "argument for #{self.class}"
            end
          end
        end

        # :nodoc:
        def defaults
          { model: nil, media_type: nil }
        end

        # :nodoc:
        def pre_initialize(args); end

        # :nodoc:
        def post_initialize(args)
          return if OCCI_TEXT_TYPES.include?(args[:media_type])
          raise Occi::Core::Errors::ParserError, "Media type #{args[:media_type].inspect} is not supported " \
                "by instances of this parser, only #{OCCI_TEXT_TYPES.inspect}"
        end
      end
    end
  end
end
