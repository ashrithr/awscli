module Awscli
  class Connection
    require 'awscli/errors'
    require 'awscli/helper'

    def initialize
      #load env variable AWSCLI_CONFIG_FILE
      @aws_config_file = ENV['AWSCLI_CONFIG_FILE']
      if @aws_config_file.nil?
        puts 'Cannot find config file environment variable'
        Awscli::Errors.missing_environment_variable
      end
      @aws_config_file_path = File.expand_path(@aws_config_file)
      unless File.exist?(@aws_config_file_path)
        puts "Cannot locate file #{@aws_config_file}"
        Awscli::Errors.missing_config_file
      end
      @config = YAML.load(File.read(@aws_config_file_path))
      unless @config.kind_of?(Hash)
        puts 'Parse Error'
        Awscli::Errors.missing_credentials
      end
    end

    def request_ec2(region=nil)
      # => returns AWS Compute connection object
      @config.merge!(:provider => 'AWS')
      if region
        #if user passes a region optionally
        Awscli::Errors.invalid_region unless Awscli::Instances::REGIONS.include?(region)
        @config.reject!{ |key| key == 'region' } if @config['region']
        @config.merge!(:region => region)
      else
        Awscli::Errors.invalid_region unless Awscli::Instances::REGIONS.include?(@config['region']) if @config['region']
      end
      Fog::Compute.new(@config)
    end

    def request_s3(region=nil)
      # => returns S3 connection object
      @config.merge!(:provider => 'AWS')
      @config.reject!{ |key| key == 'region' } if @config['region']
      #parse optionally passing region
      if region
        Awscli::Errors.invalid_region unless Awscli::Instances::REGIONS.include?(region)
        @config.merge!(:region => region)
      end
      Fog::Storage.new(@config)
    end

    def request_as
      # => returns AWS Auto Scaling connection object
      Fog::AWS::AutoScaling.new(@config)
    end

    def request_iam
      # => returns AWS IAM object
      @config.reject!{ |key| key == 'region' } if @config['region']
      Fog::AWS::IAM.new(@config)
    end

    def request_emr(region=nil)
      # => returns AWS EMR object
      if region
        Awscli::Errors.invalid_region unless Awscli::Instances::REGIONS.include?(region)
        @config.reject!{ |key| key == 'region' } if @config['region']
        @config.merge!(:region => region)
      else
        Awscli::Errors.invalid_region unless Awscli::Instances::REGIONS.include?(@config['region']) if @config['region']
      end
      Fog::AWS::EMR.new(@config)
    end

    def request_dynamo(region=nil)
      # => returns AWS DynamoDB object
      if region
        Awscli::Errors.invalid_region unless Awscli::Instances::REGIONS.include?(region)
        @config.reject!{ |key| key == 'region' } if @config['region']
        @config.merge!(:region => region)
      else
        Awscli::Errors.invalid_region unless Awscli::Instances::REGIONS.include?(@config['region']) if @config['region']
      end
      Fog::AWS::DynamoDB.new(@config)
    end

  end
end