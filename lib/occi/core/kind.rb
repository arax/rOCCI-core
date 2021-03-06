module Occi
  module Core
    # Defines the classification system of the OCCI Core Model. The `Kind`
    # instance represents the type identification mechanism for all `Entity`
    # instances present in the model.
    #
    # @example
    #   Kind.new schema: 'http://schemas.ogf.org/occi/infrastructure#',
    #            term: 'compute',
    #            title: 'Compute'
    #
    # @attr parent [Kind] previous `Kind` in the OCCI kind hierarchy
    # @attr actions [Set] list of `Action` instances applicable to this `Kind`
    # @attr location [URI] protocol agnostic location of this `Kind` instance
    #
    # @author Boris Parak <parak@cesnet.cz>
    class Kind < Category
      include Helpers::Locatable

      attr_accessor :parent, :actions
      attr_writer :location

      # Checks whether the given `Kind` instance is related
      # to this instance. The given `Kind` instance must be
      # included in the list of predecessors (see `#related`)
      # to succeed.
      #
      # @param kind [Kind] suspected predecessor
      # @return [TrueClass, FalseClass] result
      def related?(kind)
        return false unless kind
        return true if kind == self
        related.include? kind
      end

      # Checks whether the given `Kind` instance is related
      # to this instance. The given `Kind` instance must be
      # the immediate predecessor (see `#directly_related`)
      # to succeed.
      #
      # @param kind [Kind] suspected predecessor
      # @return [TrueClass, FalseClass] result
      def directly_related?(kind)
        return false unless kind
        return true if kind == self
        directly_related.include? kind
      end

      # Transitively returns all predecessors of this `Kind` instance in
      # a multi-element `Array`.
      #
      # @return [Array] list containing predecessors of this `Kind` instance
      def related
        return directly_related if hierarchy_root?
        [parent, parent.related].flatten.compact
      end

      # For compatibility reasons, returns the parent instance of this `Kind` in
      # an `Array`. For hierarchy roots, returns only an empty `Array`.
      #
      # @return [Array] a list containing the parent `Kind` instance, if any
      def directly_related
        [parent].compact
      end

      # Indicates whether this instance is the base of the OCCI kind
      # hierarchy, i.e. there are no predecessors. This helps to
      # calculate the relationship status correctly, see `#related`.
      #
      # @return [TrueClass, FalseClass] result
      def hierarchy_root?
        parent.nil?
      end

      protected

      # :nodoc:
      def defaults
        super.merge(parent: nil, actions: Set.new, location: nil)
      end

      # :nodoc:
      def sufficient_args!(args)
        super
        [:actions].each do |attr|
          if args[attr].nil?
            raise Occi::Core::Errors::MandatoryArgumentError, "#{attr} is a mandatory " \
                  "argument for #{self.class}"
          end
        end
      end

      # :nodoc:
      def post_initialize(args)
        super
        @parent = args.fetch(:parent)
        @actions = args.fetch(:actions)
        @location = args.fetch(:location)

        load_parent_attributes! if parent
      end

      # :nodoc:
      def load_parent_attributes!
        attributes.merge!(parent.attributes) { |_, oldval, _| oldval }
      end

      private

      # Generates default location based on the already configured
      # `term` attribute. Fails if `term` is not present.
      #
      # @example
      #   kind.term              # => 'compute'
      #   kind.generate_location # => #<URI::Generic /compute/>
      #
      # @return [URI] generated location
      def generate_location
        if term.blank?
          raise Occi::Core::Errors::MandatoryArgumentError,
                'Cannot generate default location without a `term`'
        end
        URI.parse "/#{term}/"
      end
    end
  end
end
