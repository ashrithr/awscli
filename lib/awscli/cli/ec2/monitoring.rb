module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class MonitoringInstances < Thor

        desc "list", "List Images"
        def list
          puts "Listing Images"
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::MonitoringInstances, :mont, 'mont [COMMAND]', 'EC2 Instances Monitoring Management'

      end
    end
  end
end