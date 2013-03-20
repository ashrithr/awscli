module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class SpotInstancesManagement < Thor

        desc "list", "List spot instances"
        def list
          puts "Listing spots"
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::SpotInstancesManagement, :spot, 'spot [COMMAND]', 'EC2 Spot Instances Management'

      end
    end
  end
end