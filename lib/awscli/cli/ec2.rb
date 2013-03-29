module AwsCli
  module CLI
    require 'awscli/cli'
    require 'awscli/connection'
    require 'awscli/ec2'
    class Ec2 < Thor
      class_option :region, :type => :string, :desc => "region to connect to", :default => 'us-west-1'

      AwsCli::Cli.register AwsCli::CLI::Ec2, :ec2, 'ec2 [COMMAND]', 'Elastic Cloud Compute Interface'
    end
  end
end