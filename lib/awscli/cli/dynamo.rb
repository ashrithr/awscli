module AwsCli
  module CLI
    require 'awscli/cli'
    require 'awscli/connection'
    require 'awscli/dynamo'
    class Dynamo < Thor
      class_option :region, :type => :string, :desc => 'region to connect to', :default => 'us-west-1'

      AwsCli::Cli.register AwsCli::CLI::Dynamo, :dynamo, 'dynamo [COMMAND]', 'Amazons NoSQL DynamoDB Interface'
    end
  end
end