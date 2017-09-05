require 'occi/core/renderers/json/base'
require 'occi/core/renderers/json/instance'

module Occi
  module Core
    module Renderers
      module Json
        # Implements routines required to render `Occi::Core::Link` and
        # its subclasses to a JSON-based representation.
        #
        # @author Boris Parak <parak@cesnet.cz>
        class Link < Base
          include Instance

          # Note: this is a hack for typing `source` on known Compute links
          COMPUTE_KIND  = 'http://schemas.ogf.org/occi/infrastructure#compute'.freeze
          COMPUTY_LINKS = %w[
            http://schemas.ogf.org/occi/infrastructure#networkinterface
            http://schemas.ogf.org/occi/infrastructure#storagelink
            http://schemas.ogf.org/occi/infrastructure#securitygrouplink
          ].freeze

          # :nodoc:
          def render_hash
            base = render_instance_hash
            base[:source] = typed_uri_hash(object_source, :source) if object_source
            base[:target] = typed_uri_hash(object_target, :target) if object_target
            base
          end

          # :nodoc:
          def typed_uri_hash(attribute, type)
            hsh = { location: attribute.to_s }

            known_kind = object_send("#{type}_kind")
            hsh[:kind] = known_kind.identifier if known_kind

            # Note: this is a hack for typing `source` on known Compute links
            if hsh[:kind].blank? && type == :source && COMPUTY_LINKS.include?(object_kind.identifier)
              hsh[:kind] = COMPUTE_KIND
            end

            hsh
          end
        end
      end
    end
  end
end
