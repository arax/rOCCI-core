module Occi
  module Core
    module Helpers
      # Introduces instance attribute resetting functionality to
      # the receiver. Provides methods for applying defaults and
      # adding attributes on top of existing base attributes.
      # `base_attributes` and `added_attributes` must be implemented
      # in the receiver.
      #
      # @author Boris Parak <parak@cesnet.cz>
      module InstanceAttributeResetter
        # Shorthand for running `reset_attributes` with the `force` flag on.
        # This method will force defaults from definitions in all available
        # attributes. No longer defined attributes will be automatically removed.
        def reset_attributes!
          reset_attributes true
        end

        # Shorthand for running `reset_base_attributes` with the `force` flag on.
        # This method will force defaults from definitions in all available
        # attributes. No longer defined attributes will be kept unchanged.
        def reset_base_attributes!
          reset_base_attributes true
        end

        # Shorthand for running `reset_added_attributes` with the `force` flag on.
        # This method will force defaults from definitions in all available
        # attributes. No longer defined attributes will be kept unchanged.
        def reset_added_attributes!
          reset_added_attributes true
        end

        # Iterates over available attribute definitions and
        # sets corresponding fields in `attributes`. When using the `force` flag, all
        # existing attribute values will be replaced by defaults from definitions or
        # reset to `nil`. No longer defined attributes will be automatically removed.
        #
        # @param force [TrueClass, FalseClass] forcibly change attribute values to defaults
        def reset_attributes(force = false)
          reset_base_attributes force
          reset_added_attributes force
          remove_undef_attributes
        end

        # Removes attributes (definition and value) if they are no longer defined
        # for this instance. This is automatically called when invoking reset via
        # `reset_attributes` or `reset_attributes!`, in all other cases it has to
        # be triggered explicitly. Attributes without definitions will be removed
        # as well.
        #
        # @return [Hash] updated attribute hash
        def remove_undef_attributes
          name_cache = attribute_names
          attributes.keep_if do |key, value|
            defined = name_cache.include?(key) && value && value.attribute_definition
            logger.debug { "Removing undefined attribute #{key.inspect} on #{self.class}" } unless defined
            defined
          end
        end

        # Collects all available attribute names into a list. Without definitions
        # or values.
        #
        # @return [Array] list available attribute names
        def attribute_names
          names = added_attributes.collect(&:keys)
          names << base_attributes.keys
          names.flatten!
          names.compact!

          names
        end

        # Iterates over available base attribute definitions and
        # sets corresponding fields in `attributes`. When using the `force` flag, all
        # existing attribute values will be replaced by defaults from definitions or
        # reset to `nil`. No longer defined attributes will be kept unchanged.
        #
        # @param force [TrueClass, FalseClass] forcibly change attribute values to defaults
        # @return [Array] list of processed attribute names
        def reset_base_attributes(force = false)
          processed_attrs = []

          base_attributes.each_pair do |name, definition|
            processed_attrs << name
            reset_attribute(name, definition, force)
          end

          processed_attrs
        end

        # Iterates over available added attribute definitions and
        # sets corresponding fields in `attributes`. When using the `force` flag, all
        # existing attribute values will be replaced by defaults from definitions or
        # reset to `nil`. No longer defined attributes will be kept unchanged.
        #
        # @param force [TrueClass, FalseClass] forcibly change attribute values to defaults
        # @return [Array] list of processed attribute names
        def reset_added_attributes(force = false)
          processed_attrs = []

          added_attributes.each do |attrs|
            attrs.each_pair do |name, definition|
              if processed_attrs.include?(name)
                raise Occi::Core::Errors::AttributeDefinitionError,
                      "Attribute #{name.inspect} already modified by another mixin"
              end
              processed_attrs << name
              reset_attribute(name, definition, force)
            end
          end

          processed_attrs
        end

        # Sets corresponding attribute fields in `attributes`. When using the `force` flag, any
        # existing attribute value will be replaced by the default from its definition or
        # reset to `nil`.
        #
        # @param name [String] attribute name
        # @param definition [AttributeDefinition] attribute definition
        # @param force [TrueClass, FalseClass] forcibly change attribute value to default
        def reset_attribute(name, definition, force)
          if attributes[name]
            logger.debug { "Setting attribute definition for existing #{name.inspect} on #{self.class}" }
            attributes[name].attribute_definition = definition
          else
            logger.debug { "Creating attribute definition for new #{name.inspect} on #{self.class}" }
            attributes[name] = Attribute.new(nil, definition)
          end

          force ? attributes[name].default! : attributes[name].default
        end
      end
    end
  end
end
