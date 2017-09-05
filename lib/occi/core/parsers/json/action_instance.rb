module Occi
  module Core
    module Parsers
      module Json
        # Static parsing class responsible for extracting action instances from JSON.
        # Class supports 'application/json' via `json`. No other formats are supported.
        #
        # @author Boris Parak <parak@cesnet.cz>
        class ActionInstance
          include Yell::Loggable
          include Helpers::ErrorHandler
          extend Helpers::RawJsonParser

          class << self
            # Parses action instances. Internal references between objects are converted from strings
            # to actual objects. Actions have to be declared in the provided model.
            #
            # @param body [String] JSON body for parsing
            # @param model [Occi::Core::Model] model with existing categories
            # @return [Occi::Core::ActionInstance] action instance
            def json(body, model)
              parsed = raw_hash(body)
              action = handle(Occi::Core::Errors::ParsingError) { model.find_by_identifier! parsed[:action] }

              logger.debug { "Identified #{action.class}[#{action.identifier}]" }
              ai = Occi::Core::ActionInstance.new(action: action)
              ep = Entity.new(model: model)
              ep.set_attributes!(ai, parsed[:attributes]) if parsed[:attributes]

              logger.debug { "Parsed into ActionInstance #{ai.inspect}" }
              ai
            end
          end
        end
      end
    end
  end
end
