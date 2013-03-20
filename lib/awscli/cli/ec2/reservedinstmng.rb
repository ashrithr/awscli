module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class ReservedInstances < Thor

        desc "list", "List ReservedInstances"
        def list
          puts "Listing ReservedInstances"
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::ReservedInstances, :resv, 'resv [COMMAND]', 'EC2 ReservedInstances Management'

      end
    end
  end
end