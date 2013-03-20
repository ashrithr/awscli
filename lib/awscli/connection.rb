module Awscli
  class Connection
    # require 'awscli/errors'
    # require 'awscli/helper'

    def initialize
      #load env variable AWSCLI_CONFIG_FILE
      @@aws_config_file = ENV['AWSCLI_CONFIG_FILE']
      unless !@@aws_config_file.nil?
        puts "Cannot find config file environment variable".color :red
        Awscli::Errors.missing_environment_variable
      end
      @@aws_config_file_path = File.expand_path(@@aws_config_file)
      unless File.exist?(@@aws_config_file_path)
        puts "Cannot locate file #{@@aws_config_file}".color :red
        Awscli::Errors.missing_config_file
      end
      @@config = YAML.load(File.read(@@aws_config_file_path))
      unless @@config.kind_of?(Hash)
        puts "Parse Error".color :red
        Awscli::Errors.missing_credentials
      end
    end

    def request_ec2
      # => returns AWS Compute connection object
      @@config.merge!(:provider => 'AWS')
      if @@config['region']
        Awscli::Errors.invalid_region unless Awscli::Instances::REGIONS.include?(@@config['region'])
      end
      Fog::Compute.new(@@config)
    end

    def request_as
      # => returns AWS Auto Scaling connection object
      Fog::AWS::AutoScaling.new(@@config)
    end

  end
end