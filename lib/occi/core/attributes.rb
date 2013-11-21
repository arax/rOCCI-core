module Occi
  module Core
    class Attributes < Hashie::Mash

      attr_accessor :converted

      include Occi::Helpers::Inspect
      include Occi::Helpers::Comparators::Attributes

      BOOLEAN_CLASSES = [TrueClass, FalseClass]

      def initialize(source_hash = {}, default = nil, &blk)
        raise ArgumentError, 'Source_hash is a mandatory argument!' unless source_hash
        raise ArgumentError, 'Source_hash must be a hash-like structure!' unless source_hash.kind_of?(Hash)

        # All internal Hashie::Mash elements in source_hash have to be re-typed
        # to Occi::Core::Attributes, so we have to rebuild the object from scratch
        source_hash = source_hash.to_hash unless source_hash.kind_of?(Occi::Core::Attributes)

        super(source_hash, default, &blk)
      end

      def converted?
        @converted||=false
      end

      def [](key)
        if key.to_s.include? '.'
          key, string = key.to_s.split('.', 2)
          attributes = super(key)
          raise Occi::Errors::AttributeMissingError, "Attribute with key #{key} not found" unless attributes
          attributes[string]
        else
          super(key)
        end
      end

      def []=(key, value)
        if key.to_s.include? '.'
          key, string = key.to_s.split('.', 2)
          super(key, Occi::Core::Attributes.new) unless self[key].kind_of? Occi::Core::Attributes
          self[key][string] = value
        else
          property_key = "_#{key.to_s}"
          validate_and_assign(key, value, property_key)
        end
      end

      def remove(attributes)
        attributes.keys.each do |key|
          if self.keys.include? key
            case self[key]
              when Occi::Core::Attributes
                self[key].remove attributes[key]
              else
                self.delete(key)
            end
          end
        end
        self
      end

      def convert(attributes=Occi::Core::Attributes.new(self))
        attributes.each_pair do |key, value|
          next if key =~ /^_/
          case value
            when Occi::Core::Attributes
              value.convert!
            else
              attributes[key] = nil
          end
        end
        attributes.converted = true
        attributes
      end

      def convert!
        convert self
      end

      # @return [Hash] key value pair of full attribute names with their corresponding values
      def names
        hash = {}
        self.each_key do |key|
          next if key =~ /^_/
          if self[key].kind_of? Occi::Core::Attributes
            self[key].names.each_pair { |k, v| hash["#{key}.#{k}"] = v unless v.nil? }
          else
            hash[key] = self[key]
          end
        end
        hash
      end

      # @param [Hash] attributes
      # @return [Occi::Core::Attributes] parsed attributes with properties
      def self.parse_properties(hash)
        hash ||= {}
        raise Occi::Errors::ParserInputError, 'Hash must be a hash-like structure!' unless hash.respond_to?(:each_pair)

        attributes = Occi::Core::Attributes.new
        hash.each_pair do |key, value|
          if Occi::Core::Properties.contains_props?(value)
            attributes[key] = Occi::Core::Properties.new(value)
          else
            attributes[key] = self.parse_properties(attributes[key])
          end
        end

        attributes
      end

      # @param [Hash] attributes key value pair of full attribute names with their corresponding values
      # @return [Occi::Core::Attributes]
      def self.split(attributes)
        attribute = Attributes.new
        attributes.each do |name, value|
          key, _, rest = name.partition('.')
          if rest.blank?
            attribute[key] = value
          else
            attribute.merge! Attributes.new(key => self.split(rest => value))
          end
        end

        attribute
      end

      # @return [String]
      def to_string
        attributes = ';'
        attributes << to_header.gsub(',', ';')

        attributes == ';' ? '' : attributes
      end

      # @return [String]
      def to_string_short
        any? ? ";attributes=#{names.keys.join(' ').inspect}" : ""
      end

      # @return [String]
      def to_text
        text = ""
        names.each_pair do |name, value|
          # TODO: find a better way to skip properties
          next if name.include? '._'
          case value
            when Occi::Core::Entity
              text << "\nX-OCCI-Attribute: #{name}=\"#{value.location}\""
            when Occi::Core::Category
              text << "\nX-OCCI-Attribute: #{name}=\"#{value.type_identifier}\""
            else
              text << "\nX-OCCI-Attribute: #{name}=#{value.inspect}"
          end
        end

        text
      end

      # @return [String] of attributes put in an array and then concatenated into a string
      def to_header
        attributes = []
        names.each_pair do |name, value|
          # TODO: find a better way to skip properties
          next if name.include? '._'
          prop = "#{name.gsub(/([^.]+?)$/,'_\1')}"
          sep = (self[prop] && self[prop].type != "string") ? '' : '"'
          attributes << "#{name}=#{sep}#{value.to_s}#{sep}"
        end

        attributes.join(',')
      end

      def to_json(*a)
        as_json(*a).to_json(*a)
      end

      # @param [Hash] options
      # @return [Hashie::Mash] json representation
      def as_json(options={})
        hash = Hashie::Mash.new
        self.each_pair do |key, value|
          next if key =~ /^_/
          # TODO: find a better way to skip properties
          next if key.start_with? '_'

          case value
            when Occi::Core::Attributes
              hash[key] = value.as_json if value && value.as_json.size > 0
            when Occi::Core::Entity
              hash[key] = value.to_s unless value.blank?
            when Occi::Core::Category
              hash[key] = value.to_s
            else
              hash[key] = value.as_json unless value.nil?
          end
        end

        hash
      end

      # @param [Occi::Core::Attributes] definitions
      # @param [true,false] set_defaults
      # @return [Occi::Core::Attributes] attributes with their defaults set
      def check(definitions, set_defaults = false)
        attributes = Occi::Core::Attributes.new(self)
        attributes.check!(definitions, set_defaults)
        attributes
      end

      # @param [Occi::Core::Attributes] definitions
      # @param [true,false] set_defaults
      # Assigns default values to attributes
      def check!(definitions, set_defaults = false)
        raise Occi::Errors::AttributeDefinitionsConvrertedError, "definition attributes must not be converted" if definitions.converted?

        # Start with checking for missing attributes
        add_missing_attributes(self, definitions, set_defaults)

        # Then check all attributes against definitions
        check_wrt_definitions(self, definitions, set_defaults)

        # Delete remaining empty attributes
        delete_empty(self, definitions)

      end

      private

      def validate_and_assign(key, value, property_key)
        raise Occi::Errors::AttributeNameInvalidError, "Attribute names (as in \"#{key}\") must not begin with underscores" if key =~ /^_/
        case value
        when Occi::Core::Attributes
          add_to_hashie(key, value)
        when Occi::Core::Properties
          add_to_hashie(key, value.clone)
          add_to_hashie(property_key, value.clone)
        when Hash
          properties = Occi::Core::Properties.new(value)
          add_to_hashie(key, properties.clone)
          add_to_hashie(property_key, properties.clone)
        when Occi::Core::Entity
          match_type(value, self[property_key], 'string') if self[property_key]
          add_to_hashie(key, value)
        when Occi::Core::Category
          match_type(value, self[property_key], 'string') if self[property_key]
          add_to_hashie(key, value)
        when String
          match_type(value, self[property_key], 'string') if self[property_key]
          add_to_hashie(key, value)
        when Numeric
          match_type(value, self[property_key], 'number') if self[property_key]
          add_to_hashie(key, value)
        when FalseClass, TrueClass
          match_type(value, self[property_key], 'boolean') if self[property_key]
          add_to_hashie(key, value)
        when NilClass
          add_to_hashie(key, value)
        else
          raise Occi::Errors::AttributeTypeError, "value #{value} of type #{value.class} not supported as attribute"
        end
      end

      def add_to_hashie(*args)
        Hashie::Mash.instance_method(:[]=).bind(self).call(*args)
      end

      def match_type(value, property, expected_type)
        raise Occi::Errors::AttributeTypeError, "value #{value} derived from #{value.class} assigned but attribute of type #{property.type} required" unless property.type == expected_type
        match_pattern(property.pattern, value)
      end

      def match_pattern(pattern, value)
        return if pattern.blank?

        if Occi::Settings.verify_attribute_pattern && !Occi::Settings.compatibility
          raise Occi::Errors::AttributeTypeError, "value #{value.to_s} does not match pattern #{pattern}" unless value.to_s.match "^#{pattern}$"
        else
          Occi::Log.warn "[#{self.class}] Skipping pattern checks on attributes, turn off the compatibility mode and enable the attribute pattern check in settings!"
        end
      end

      def add_missing_attributes(attributes, definitions, set_defaults)
        definitions.each_key do |key|
          next if key =~ /^_/

          if definitions[key].kind_of? Occi::Core::Attributes
            add_missing_attributes(attributes[key], definitions[key], set_defaults)

          elsif !attributes.key?(key) or attributes[key].nil?

            if definitions[key].default.nil?
              raise Occi::Errors::AttributeMissingError, "Required attribute #{key} not specified" if definitions[key].required
            else
              attributes[key] = definitions[key].default if definitions[key].required or set_defaults
            end

          end
        end
      end

      def check_wrt_definitions(attributes, definitions, set_defaults)

        attributes.each_key do |key|
          next if key =~ /^_/

          if attributes[key].kind_of? Occi::Core::Attributes
            check_wrt_definitions(attributes[key], definitions[key], set_defaults)

          else
            
            #Raise exception for attributes not defined at all
            raise Occi::Errors::AttributeNotDefinedError, "Attribute #{key} not found in definitions" unless definitions.key?(key)
            
            #Set defaults if values not set, missing attributes have already been added and set to default in add_missing_attributes()
            attributes[key] = definitions[key].default if attributes[key].nil? and set_defaults and !definitions[key].default.nil?

            next if attributes[key].nil? # I will be removed in the next step

            #Check value types
            case definitions[key].type
              when 'number'
                raise Occi::Errors::AttributeTypeError, "attribute #{key} with value #{attributes[key]} from class #{attributes[key].class.name} does not match attribute property type #{definitions[key].type}" unless attributes[key].kind_of?(Numeric)
              when 'boolean'
                raise Occi::Errors::AttributeTypeError, "attribute #{key} with value #{attributes[key]} from class #{attributes[key].class.name} does not match attribute property type #{definitions[key].type}" unless !!attributes[key] == attributes[key]
              when 'string'
                raise Occi::Errors::AttributeTypeError, "attribute #{key} with value #{attributes[key]} from class #{attributes[key].class.name} does not match attribute property type #{definitions[key].type}" unless attributes[key].kind_of?(String)
              else
                raise Occi::Errors::AttributePropertyTypeError, "property type #{definitions[key].type} is not one of the allowed types number, boolean or string"
            end

            # Check patterns
            if definitions[key].pattern
              if Occi::Settings.verify_attribute_pattern && !Occi::Settings.compatibility
                raise Occi::Errors::AttributeTypeError, "attribute #{key} with value #{attributes[key]} does not match pattern #{definitions[key].pattern}" unless attributes[key].to_s.match "^#{definitions[key].pattern}$"
              else
                Occi::Log.warn "[#{key}] Skipping pattern checks on attributes, turn off the compatibility mode and enable the attribute pattern check in settings!"
              end
            end
          end
        end
      end

      def delete_empty(attributes, definitions)

        attributes.each_key do |key|
          next if key =~ /^_/

          if attributes[key].kind_of? Occi::Core::Attributes
            delete_empty(attributes[key], definitions[key])

          else
            attributes.delete(key) if attributes[key].nil?
          end
        end
      end
    end
  end
end
