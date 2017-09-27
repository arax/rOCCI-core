module Occi
  module Core
    module Helpers
      # Introduces JSON parsing to various parser classes. This allowes
      # parsers to convert JSON-formatted text into hashes.
      #
      # @author Boris Parak <parak@cesnet.cz>
      module RawJsonParser
        # :nodoc:
        def raw_hash(body)
          JSON.parse body, symbolize_names: true
        rescue StandardError => ex
          raise Occi::Core::Errors::ParsingError, "JSON parsing failed: #{ex.message}"
        end
      end
    end
  end
end
