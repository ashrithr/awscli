module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class KeyPairs < Thor

        desc "list", "List Key Pairs"
        def list
          puts "Listing Key Pairs"
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::KeyPairs, :kp, 'kp [COMMAND]', 'EC2 Key Pair Management'

      end
    end
  end
end