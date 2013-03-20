module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class VPC < Thor

        desc "list", "List VPCs"
        def list
          puts "Listing VPCs"
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::VPC, :vpc, 'vpc [COMMAND]', 'EC2 VPC Management'

      end
    end
  end
end