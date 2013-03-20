module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class Tags < Thor

        desc "list", "List tags"
        def list
          puts "Listing tags"
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::Tags, :tags, 'tags [COMMAND]', 'EC2 Tags Management'

      end
    end
  end
end