module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class Ebs < Thor

        desc "list", "List Block Storages"
        def list
          puts "Listing EBS"
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::Ebs, :ebs, 'ebs [COMMAND]', 'EC2 EBS Management'

      end
    end
  end
end