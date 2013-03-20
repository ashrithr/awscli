module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class Placement < Thor

        desc "list", "List Images"
        def list
          puts "Listing Images"
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::Placement, :place, 'place [COMMAND]', 'EC2 Placement Management'

      end
    end
  end
end