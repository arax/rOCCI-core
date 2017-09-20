module Occi
  module InfrastructureExt
    # Extended loader for static categories defined in the OCCI Infra Ext Standard
    # published by OGF's OCCI WG. This warehouse is meant to be used as a
    # quick bootstrap tools for `Occi::Infrastructure::Model` instances. Instances passed
    # to this warehouse MUST be already boostrapped by `Occi::Infrastructure::Warehouse`.
    #
    # @author Boris Parak <parak@cesnet.cz>
    class Warehouse < Occi::Infrastructure::Warehouse
      class << self
        protected

        # :nodoc:
        def whereami
          __dir__
        end
      end
    end
  end
end
