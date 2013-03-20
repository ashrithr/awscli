module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class SecGroups < Thor

        desc "list", "List Security Groups"
        def list
          puts "Listing Security Groups"
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::SecGroups, :sg, 'sg [COMMAND]', 'EC2 Security Groups Management'

      end
    end
  end
end