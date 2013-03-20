module Awscli
  module EC2
    class EC2

      def initialize connection, options = {}
        @@conn = connection
      end

      def list_instances
        @@conn.servers.table([:id, :dns_name, :flavor_id, :groups, :image_id, :key_name, :private_ip_address,
          :public_ip_address, :root_device_type, :security_group_ids, :state, :tags])
      end

      def list_keypairs
        @@conn.key_pairs.table
      end

      def list_secgroups
        @@conn.security_groups.table([:name, :group_id, :description])
      end

      def list_flavors
        @@conn.flavors.table
      end

      def list_images_amazon
        @@conn.images.all('owner-id' => '470254534024').table([:architecture, :id, :is_public, :platform,
                                                                  :root_device_type, :state])
      end

      def create_instance

      end

    end
  end
end