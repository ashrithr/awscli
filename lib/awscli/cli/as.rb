module AwsCli
  module CLI
    require 'awscli/cli'
    require 'awscli/connection'
    require 'awscli/as'
    class As < Thor
      class_option :region, :type => :string, :desc => 'region to connect to'

      AwsCli::Cli.register AwsCli::CLI::As, :as, 'as [COMMAND]', 'Auto Scaling Interface'
    end
  end
end