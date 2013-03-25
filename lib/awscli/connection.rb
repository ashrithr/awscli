module Awscli
  class Connection
    require 'awscli/errors'
    require 'awscli/helper'

    def initialize
      #load env variable AWSCLI_CONFIG_FILE
      @@aws_config_file = ENV['AWSCLI_CONFIG_FILE']
      unless !@@aws_config_file.nil?
        puts "Cannot find config file environment variable"
        Awscli::Errors.missing_environment_variable
      end
      @@aws_config_file_path = File.expand_path(@@aws_config_file)
      unless File.exist?(@@aws_config_file_path)
        puts "Cannot locate file #{@@aws_config_file}"
        Awscli::Errors.missing_config_file
      end
      @@config = YAML.load(File.read(@@aws_config_file_path))
      unless @@config.kind_of?(Hash)
        puts "Parse Error"
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

    def request_s3 region=nil
      # => returns S3 connection object
      @@config.merge!(:provider => 'AWS')
      if @@config['region']
        #remove region
        @@config.reject!{ |k| k == "region" }
      end
      #parse optionally passing region
      if region
        Awscli::Errors.invalid_region unless Awscli::Instances::REGIONS.include?(region)
        @@config.merge!(:region => region)
      end
      Fog::Storage.new(@@config)
    end

    def request_as
      # => returns AWS Auto Scaling connection object
      Fog::AWS::AutoScaling.new(@@config)
    end

  end
end