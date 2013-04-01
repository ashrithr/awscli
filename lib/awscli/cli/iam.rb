module AwsCli
  module CLI
    require 'awscli/cli'
    require 'awscli/connection'
    require 'awscli/iam'
    class Iam < Thor
      AwsCli::Cli.register AwsCli::CLI::Iam, :iam, 'iam [COMMAND]', 'AWS Identity and Access Management Interface'
    end
  end
end