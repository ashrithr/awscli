module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class Vpc < Thor

        desc "list", "List VPCs"
        def list
          create_ec2_object
          @ec2.list
        end

        desc "create", "Create a VPC with the CIDR block you specify"
        method_option :cidr_block, :aliases => "-c", :type => :string, :required => true, :desc => "The CIDR block you want the VPC to cover (e.g., 10.0.0.0/16), You can't change the size of a VPC after you create it"
        method_option :tenancy, :type => :string, :default => "default", :desc => "The allowed tenancy of instances launched into the VPC. A value of default means instances can be launched with any tenancy; a value of dedicated means instances must be launched with tenancy as dedicated"
        def create
          create_ec2_object
          @ec2.create options
        end

        desc "delete", "Deletes a VPC. You must detach or delete all gateways or other objects that are dependent on the VPC first"
        method_option :vpc_id, :aliases => "-v", :type => :string, :required => true, :desc => "The ID of the VPC you want to delete"
        def delete
          create_ec2_object
          @ec2.delete options[:vpc_id]
        end

        private

        def create_ec2_object
          puts "ec2 Establishing Connetion..."
          $ec2_conn = Awscli::Connection.new.request_ec2
          puts "ec2 Establishing Connetion... OK"
          @ec2 = Awscli::EC2::Vpc.new($ec2_conn)
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::Vpc, :vpc, 'vpc [COMMAND]', 'EC2 VPC Management'

      end
    end
  end
end