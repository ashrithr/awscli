module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class Subnet < Thor

        desc "list", "List VPCs"
        def list
          create_ec2_object
          @ec2.list
        end

        desc "create", "Create a subnet in an existing VPC, You can create up to 20 subnets in a VPC."
        method_option :vpc_id, :aliases => "-v", :type => :string, :required => true, :desc => "The ID of the VPC where you want to create the subnet"
        method_option :cidr_block, :aliases => "-c", :type => :string, :required => true, :desc => "The CIDR block you want the subnet to cover (e.g., 10.0.0.0/24)"
        method_option :availability_zone, :aliases => "-z", :type => :string, :desc => "The Availability Zone you want the subnet in. Default: AWS selects a zone for you (recommended)"
        def create
          create_ec2_object
          @ec2.create options
        end

        desc "delete", "Delete a subnet"
        method_option :subnet_id, :aliases => "-s", :type => :string, :required => true, :desc => "The ID of the subnet you want to delete"
        def delete
          create_ec2_object
          @ec2.delete options[:subnet_id]
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
          @ec2 = Awscli::EC2::Subnet.new($ec2_conn)
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::Subnet, :subnet, 'subnet [COMMAND]', 'EC2 Subnet Management'

      end
    end
  end
end