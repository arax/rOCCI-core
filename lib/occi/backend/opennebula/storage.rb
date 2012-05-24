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
# Description: OpenNebula Backend
# Author(s): Hayati Bice, Florian Feldhaus, Piotr Kasprzak
##############################################################################

require 'occi/log'

module OCCI
  module Backend
    module OpenNebula

      # ---------------------------------------------------------------------------------------------------------------------
      module Storage

        TEMPLATESTORAGERAWFILE = 'storage.erb'

        # ---------------------------------------------------------------------------------------------------------------------       
        #        private
        # ---------------------------------------------------------------------------------------------------------------------

        # ---------------------------------------------------------------------------------------------------------------------     
        def storage_parse_backend_object(backend_object)

          # get information on storage object from OpenNebula backend
          backend_object.info

          storage_kind = OCCI::Registry.get_by_id("http://schemas.ogf.org/occi/infrastructure#storage")

          storage = OCCI::Core::Resource.new

          storage.kind = storage_kind.type_identifier
          storage.mixins = [OCCI::Registry.get_by_id('http://opennebula.org/occi/infrastructure#storage')]
          storage.id = backend_object['TEMPLATE/OCCI_ID']||= self.generate_occi_id(storage_kind, backend_object.id.to_s)
          storage.title = backend_object['NAME']
          storage.summary = backend_object['TEMPLATE/DESCRIPTION'] if backend_object['TEMPLATE/DESCRIPTION']

          storage.attributes!.occi!.storage!.size = backend_object['TEMPLATE/SIZE'].to_f/1000 if backend_object['TEMPLATE/SIZE']

          storage.attributes!.org!.opennebula!.storage!.type = backend_object['TEMPLATE/TYPE'] if backend_object['TEMPLATE/TYPE']
          storage.attributes!.org!.opennebula!.storage!.persistent = backend_object['TEMPLATE/PERSISTENT'] if backend_object['TEMPLATE/PERSISTENT']
          storage.attributes!.org!.opennebula!.storage!.dev_prefix = backend_object['TEMPLATE/DEV_PREFIX'] if backend_object['TEMPLATE/DEV_PREFIX']
          storage.attributes!.org!.opennebula!.storage!.bus = backend_object['TEMPLATE/BUS'] if backend_object['TEMPLATE/BUS']
          storage.attributes!.org!.opennebula!.storage!.driver = backend_object['TEMPLATE/DRIVER'] if backend_object['TEMPLATE/DRIVER']

          storage_update_state(storage)

          # check storage attributes against definition in kind and mixins
          storage.check

          storage_kind.entities << storage
        end

        # ---------------------------------------------------------------------------------------------------------------------
        public
        # ---------------------------------------------------------------------------------------------------------------------

        # ---------------------------------------------------------------------------------------------------------------------
        def storage_deploy(storage)

          storage = Image.new(Image.build_xml, @one_client)

          template_location = OCCI::Server.config["TEMPLATE_LOCATION"] + TEMPLATESTORAGERAWFILE
          template = Erubis::Eruby.new(File.read(template_raw)).evaluate(storage)

          OCCI::Log.debug("Parsed template #{template}")
          rc = backend_object.allocate(template)
          check_rc(rc)
          OCCI::Log.debug("OpenNebula ID of image: #{storage.backend[:id]}")

          storage_update_state
        end

        # ---------------------------------------------------------------------------------------------------------------------
        def storage_update_state(storage)
          backend_object = Image.new(Image.build_xml(storage.backend[:id]), @one_client)
          backend_object.info
          OCCI::Log.debug("current Image state is: #{backend_object.state_str}")
          case backend_object.state_str
            when "READY", "USED", "LOCKED" then
              storage.attributes!.occi!.storage!.state = "online"
            when "ERROR" then
              storage.attributes!.occi!.storage!.state = "error"
            else
              storage.attributes!.occi!.storage!.state = "offline"
          end
        end

        # ---------------------------------------------------------------------------------------------------------------------
        def storage_delete(storage)
          backend_object = Image.new(Image.build_xml(storage.backend[:id]), @one_client)
          rc = backend_object.delete
          check_rc(rc)
        end

        # ---------------------------------------------------------------------------------------------------------------------
        def storage_register_all_instances
          occi_objects = []
          backend_object_pool=ImagePool.new(@one_client, OCCI::Backend::OpenNebula::OpenNebula::INFO_ACL)
          backend_object_pool.info
          backend_object_pool.each { |backend_object| storage_parse_backend_object(backend_object) }
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # STORAGE ACTIONS
        # ---------------------------------------------------------------------------------------------------------------------

        # ---------------------------------------------------------------------------------------------------------------------
        def storage_action_dummy(storage, parameters)
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # Action online
        def storage_online(network, parameters)
          backend_object = Image.new(Image.build_xml(network.backend[:id]), @one_client)
          rc = backend_object.enable
          check_rc(rc)
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # Action offline
        def storage_offline(network, parameters)
          backend_object = Image.new(Image.build_xml(network.backend[:id]), @one_client)
          rc = backend_object.disable
          check_rc(rc)
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # Action backup
        def storage_backup(network, parameters)
          OCCI::Log.debug("not yet implemented")
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # Action snapshot
        def storage_snapshot(network, parameters)
          OCCI::Log.debug("not yet implemented")
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # Action resize
        def storage_resize(network, parameters)
          OCCI::Log.debug("not yet implemented")
        end

      end
    end
  end
end