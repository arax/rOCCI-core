##############################################################################
#  Copyright 2011 Service Computing group, TU Dortmund
#  
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#      http://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
##############################################################################

##############################################################################
# Description: OCCI Extension Console Link
# Author(s): Max Günther
##############################################################################

require 'occi/CategoryRegistry'
require 'occi/core/Mixin'
require 'occi/core/Kind'
require 'occi/core/Link'

module OCCI
  module Infrastructure

    class ConsoleLink < OCCI::Core::Link
      begin
        actions = []
        related = [OCCI::Core::Link::KIND]
        entity_type = self
        entities = []

        term    = "console"
        scheme  = "http://schemas.ogf.org/occi/infrastructure/compute#"
        title   = "This is a link to the VM's console"

        attributes = OCCI::Core::Attributes.new()
        MIXIN = OCCI::Core::Mixin.new(term, scheme, title, attributes, actions, related, entities)
        
        OCCI::CategoryRegistry.register(MIXIN)
        OCCI::Rendering::HTTP::LocationRegistry.register('/consolelink/', MIXIN)
      end

      def initialize(attributes, mixins=[])
        # Initialize resource state
        super(attributes, mixins, OCCI::Infrastructure::ConsoleLink::MIXIN)
      end

    end

  end
end