module AwsCli
  module CLI
    module EC2
      module VPC
        require 'awscli/cli/ec2/vpc'
        class NetworkInterfaces < Thor

          desc "list", "List Network Interfaces"
          def list
            create_ec2_object
            @ec2.list
          end

          desc "create", "Creates a network interface in the specified subnet. This command is supported only in EC2-VPC"
          method_option :subnet_id, :aliases => "-s", :type => :string, :required => true, :desc => "subnet id"
          method_option :description, :aliases => "-d", :type => :string, :desc => "Set the description of the network interface"
          method_option :private_ip_address, :aliases => "-p", :type => :string, :desc => "The primary private IP address of the network interface. If an IP address is not specified, one will be auto-assigned to the interface"
          method_option :group_set, :aliases => "-g", :type => :array, :desc => "A security group to add to the network interface"
          def create
            create_ec2_object
            @ec2.create options
          end

          desc "delete", "Deletes a network interface. Network interfaces must be detached from an instance before they can be deleted."
          method_option :network_interface_id, :aliases => "-n", :type => :string, :required => true, :desc => "Id of the network interface to delete"
          def delete
            create_ec2_object
            @ec2.delete options[:network_interface_id]
          end

          desc "attach", "Attaches a network interface to an instance"
          method_option :network_interface_id, :aliases => "-n", :type => :string, :required => true, :desc => "ID of the network interface to attach"
          method_option :instance_id, :aliases => "-i", :type => :string, :required => true, :desc => "ID of the instance that will be attached to the network interface"
          method_option :device_index, :aliases => "-d", :type => :numeric, :required => true, :desc => "index of the device for the network interface attachment on the instance"
          def attach
            create_ec2_object
            @ec2.attach options[:network_interface_id], options[:instance_id], options[:device_index]
          end

          desc "deattach", "Detaches a network interface"
          method_option :attachment_id, :aliases => "-a", :type => :string, :required => true, :desc => "ID of the attachment to detach"
          method_option :force, :aliases => "-f", :type => :boolean, :default => false, :desc => "Set to true to force a detachment"
          def deattach
            create_ec2_object
            @ec2.deattach options[:attachment_id], options[:force]
          end

          desc "modify_attribute", "Modifies a network interface attribute. You can specify only one attribute at a time"
          method_option :network_interface_id, :aliases => "-n", :type => :string, :required => true, :desc => "The ID of the network interface you want to modify an attribute of"
          method_option :attribute, :aliases => "-a", :type => :string, :required => true, :desc => "The attribute to modify, must be one of 'description', 'groupSet', 'sourceDestCheck' or 'attachment'"
          method_option :description, :aliases => "-d", :type => :string, :desc => "New value of attribute - description"
          method_option :group_set, :aliases => "-g", :type => :array, :desc => "New value of attribute - a list of group id's"
          method_option :source_dest_check, :aliases => "-s", :type => :boolean, :desc => "New value of attribute - a boolean value"
          method_option :attachment, :aliases => "-t", :type => :hash, :desc => "a hash with: attachmentid - the attachment to change & deleteOnTermination - a boolean"
          def modify_attribute
            create_ec2_object
            @ec2.modify_attribute options
          end

          private

          def create_ec2_object
            puts "ec2 Establishing Connetion..."
            $ec2_conn = Awscli::Connection.new.request_ec2
            puts "ec2 Establishing Connetion... OK"
            @ec2 = Awscli::EC2::NetworkInterfaces.new($ec2_conn)
          end

          AwsCli::CLI::EC2::Vpc.register AwsCli::CLI::EC2::VPC::NetworkInterfaces, :netinterfaces, 'netinterfaces [COMMAND]', 'VPC Network Acl Management'

        end
      end
    end
  end
end