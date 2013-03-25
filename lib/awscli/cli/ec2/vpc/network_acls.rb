module AwsCli
  module CLI
    module EC2
      module VPC
        require 'awscli/cli/ec2/vpc'
        class NetworkAcl < Thor

          desc "list", "List NACLs"
          def list
            create_ec2_object
            @ec2.list
          end

          private

          def create_ec2_object
            puts "ec2 Establishing Connetion..."
            $ec2_conn = Awscli::Connection.new.request_ec2
            puts "ec2 Establishing Connetion... OK"
            @ec2 = Awscli::EC2::NetworkAcl.new($ec2_conn)
          end

          AwsCli::CLI::EC2::Vpc.register AwsCli::CLI::EC2::VPC::NetworkAcl, :networkacl, 'networkacl [COMMAND]', 'VPC Network Acl Management'

        end
      end
    end
  end
end