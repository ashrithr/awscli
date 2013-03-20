module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class Ami < Thor

        desc "list", "List Images"
        def list
          puts "Listing Images"
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::Ami, :ami, 'ami [COMMAND]', 'EC2 AMI Management'

      end
    end
  end
end