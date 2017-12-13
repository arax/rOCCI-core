module Occi
  module Core
    module Parsers
      module Json
        # Static parsing class responsible for extracting categories from JSON.
        # Class supports 'application/json' via `json`. No other formats are supported.
        #
        # @author Boris Parak <parak@cesnet.cz>
        class Category
          include Yell::Loggable
          include Helpers::ErrorHandler
          extend Helpers::ParserDereferencer
          extend Helpers::RawJsonParser

          # Typecasting lambdas
          TYPECASTER_HASH = {
            'boolean' => Boolean,
            'string'  => String,
            'number'  => Numeric,
            'array'   => Array,
            'object'  => Hash
          }.freeze

          # Hash constants for ParserDereferencer
          PARENT_KEY  = :parent
          APPLIES_KEY = :applies
          DEPENDS_KEY = :depends

          class << self
            # Parses categories into instances of subtypes of `Occi::Core::Category`. Internal references
            # between objects are converted from strings to actual objects. Categories provided in the model
            # will be reused but have to be declared in the parsed model as well.
            #
            # @param body [String] JSON body for parsing
            # @param model [Occi::Core::Model] model with existing categories
            # @return [Occi::Core::Model] model with all known category instances
            def json(body, model)
              parsed = raw_hash(body)
              instantiate_hashes! parsed, model
              logger.debug { "Parsed into raw hashes #{parsed.inspect}" }

              raw_categories = [parsed[:kinds], parsed[:mixins]].flatten.compact
              dereference_identifiers! model.categories, raw_categories

              logger.debug { "Returning (updated) model #{model.inspect}" }
              model
            end

            # :nodoc:
            def instantiate_hashes!(raw, model)
              raw[:kinds].each { |k| model << instatiate_hash(k, Occi::Core::Kind) } if raw[:kinds]
              raw[:mixins].each { |k| model << instatiate_hash(k, Occi::Core::Mixin) } if raw[:mixins]
              raw[:actions].each { |k| model << instatiate_hash(k, Occi::Core::Action) } if raw[:actions]
            end

            # :nodoc:
            def instatiate_hash(raw, klass)
              logger.debug { "Creating #{klass} from #{raw.inspect}" }

              obj = klass.new(
                term: raw[:term], schema: raw[:scheme], title: raw[:title],
                attributes: attribute_definitions(raw[:attributes])
              )

              if obj.respond_to?(:location)
                logger.debug { "Setting location #{raw[:location].inspect}" }
                obj.location = handle(Occi::Core::Errors::ParsingError) { URI.parse(raw[:location]) }
              end

              logger.debug { "Created category #{obj.inspect}" }
              obj
            end

            # :nodoc:
            def attribute_definitions(raw)
              return {} if raw.blank?

              attr_defs = {}
              raw.each_pair do |k, v|
                logger.debug { "Creating AttributeDefinition for #{k.inspect} from #{v.inspect}" }
                def_hsh = typecast(v)
                raise Occi::Core::Errors::ParsingError, "Attribute #{k.to_s.inspect} has no type" unless def_hsh[:type]
                fix_links!(k, def_hsh)
                attr_defs[k.to_s] = Occi::Core::AttributeDefinition.new(def_hsh)
              end

              attr_defs
            end

            # :nodoc:
            def typecast(hash)
              hash = hash.clone
              hash[:type] = TYPECASTER_HASH[hash[:type]]

              return hash if hash[:pattern].blank?
              hash[:pattern] = handle(Occi::Core::Errors::ParsingError) { Regexp.new(hash[:pattern]) }

              hash
            end

            # :nodoc:
            def lookup_applies_references!(mixin, derefd, parsed_rel)
              logger.debug { "Looking up applies from #{parsed_rel.inspect}" }
              return if parsed_rel.blank?
              parsed_rel.each { |kind| mixin.applies << first_or_die(derefd, kind) }
            end

            # :nodoc:
            def lookup_depends_references!(mixin, derefd, parsed_rel)
              logger.debug { "Looking up depens from #{parsed_rel.inspect}" }
              return if parsed_rel.blank?
              parsed_rel.each { |mxn| mixin.depends << first_or_die(derefd, mxn) }
            end

            # :nodoc:
            def fix_links!(name, definition_hash)
              return unless %w[occi.core.source occi.core.target].include?(name.to_s)
              logger.debug { "Forcing attribute type on #{name.to_s.inspect} from #{definition_hash[:type]} to URI" }
              # forcing 'string' to URI for validation purposes
              definition_hash[:type] = URI
            end

            private :lookup_applies_references!, :lookup_depends_references!, :fix_links!
          end
        end
      end
    end
  end
end
