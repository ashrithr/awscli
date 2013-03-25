module AwsCli
  module CLI
    require 'awscli/cli'
    require 'awscli/connection'
    require 'awscli/s3'
    class S3 < Thor
      class_option :region, :type => :string, :desc => "region to connect to"

      AwsCli::Cli.register AwsCli::CLI::S3, :s3, 's3 [COMMAND]', 'Simple Storage Service Interface'
    end
  end
end