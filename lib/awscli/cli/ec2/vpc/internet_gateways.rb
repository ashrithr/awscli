module AwsCli
  module CLI
    module EC2
      module VPC
        require 'awscli/cli/ec2/vpc'
        class InternetGateways < Thor

          desc "list", "List Internet Gateways"
          def list
            create_ec2_object
            @ec2.list
          end

          desc "create", "Create Internet Gateway"
          def create
            create_ec2_object
            @ec2.create
          end

          desc "delete", "Delete Internet Gateway"
          method_option :internet_gateway_id, :aliases => "-i", :type => :string, :required => true, :desc => "id of the internet gateway to delete"
          def delete
            create_ec2_object
            @ec2.delete options[:internet_gateway_id]
          end

          desc "attach", "Attach Internet Gateway"
          method_option :internet_gateway_id, :aliases => "-i", :type => :string, :required => true, :desc => "id of the internet gateway to attach"
          method_option :vpc_id, :aliases => "-v", :type => :string, :required => true, :desc => "id vpc to attach to"
          def attach
            create_ec2_object
            @ec2.attach options[:internet_gateway_id], options[:vpc_id]
          end

          desc "deattach", "Deattach Internet Gateway"
          method_option :internet_gateway_id, :aliases => "-i", :type => :string, :required => true, :desc => "id of the internet gateway to attach"
          method_option :vpc_id, :aliases => "-v", :type => :string, :required => true, :desc => "id vpc to attach to"
          def deattach
            create_ec2_object
            @ec2.deattach options[:internet_gateway_id], options[:vpc_id]
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
            @ec2 = Awscli::EC2::InternetGateways.new($ec2_conn)
          end

          AwsCli::CLI::EC2::Vpc.register AwsCli::CLI::EC2::VPC::InternetGateways, :internetgateways, 'internetgateways [COMMAND]', 'VPC Network Internet Gateway Management'

        end
      end
    end
  end
end