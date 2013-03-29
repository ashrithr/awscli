module AwsCli
  module CLI
    module EC2
      module VPC
        require 'awscli/cli/ec2/vpc'
        class Dhcp < Thor

          desc "list", "List Dhcp Options"
          def list
            create_ec2_object
            @ec2.list
          end

          desc "create", "Creates a set of DHCP options for your VPC"
          method_option :dhcp_configuration_options, :aliases => "-o", :type => :hash, :required => true, :desc => "hash of key value dhcp options(domain-name, domain-name-servers, ntp-servers, netbios-name-servers, netbios-node-type) to assign"
          def create
            create_ec2_object
            @ec2.create options[:dhcp_configuration_options]
          end

          desc "delete", "Deletes a set of DHCP options that you specify"
          method_option :dhcp_options_id, :aliases => "-d", :type => :string, :required => true, :desc => "The ID of the DHCP options set you want to delete"
          def delete
            create_ec2_object
            @ec2.delete options[:dhcp_options_id]
          end

          desc "associate", "Associates a set of DHCP options (that you've previously created) with the specified VPC. Or, associates no DHCP options with the VPC"
          method_option :dhcp_options_id, :aliases => "-d", :type => :string, :required => true, :desc => "The ID of the DHCP options you want to associate with the VPC"
          method_option :vpc_id, :aliases => "-v", :type => :string, :required => true, :desc => "The ID of the VPC you want to associate the DHCP options with"
          def associate
            create_ec2_object
            @ec2.associate options[:dhcp_options_id], options[:vpc_id]
          end

          private

          def create_ec2_object
            puts "ec2 Establishing Connetion..."
            $ec2_conn = if parent_options[:region]
                          Awscli::Connection.new.request_ec2(parent_options[:region])
                        else
                          Awscli::Connection.new.request_ec2
                        end
            puts "ec2 Establishing Connetion... OK"
            @ec2 = Awscli::EC2::Dhcp.new($ec2_conn)
          end

          AwsCli::CLI::EC2::Vpc.register AwsCli::CLI::EC2::VPC::Dhcp, :dhcp, 'dhcp [COMMAND]', 'VPC DHCP Management'

        end
      end
    end
  end
end