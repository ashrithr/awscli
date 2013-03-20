module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class Eip < Thor

        desc "list", "List Elastic IPs"
        def list
          puts "Listing EIPs"
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::Eip, :eip, 'eip [COMMAND]', 'EC2 EIP Management'

      end
    end
  end
end