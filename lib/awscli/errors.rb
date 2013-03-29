module Awscli
  module Errors
    require 'awscli/helper'

    class Error < StandardError
      attr_accessor :verbose

      def self.slurp(error, message=nil)
        new_error = new(message)
        new_error.set_backtrace(error.backtrace)
        new_error.verbose = error.message
        new_error
      end
    end

    class LoadError < LoadError; end

    class NotImplemented < Awscli::Errors::Error; end

    def self.missing_environment_variable
      message = <<-ERRMSG1.gsub(/^ {8}/, '')
        Missing AWSCLI_CONFIG_FILE environment variable
        Please export the variable 'export AWSCLI_CONFIG_FILE="~/awscli_config.yml"'
        Contents of the file should be:
        #########################################
        #Aws Credentials
        aws_access_key_id: YOUR_ACCESS_KEY
        aws_secret_access_key: YOUR_SECRET_ACCESS_KEY
        #End of Aws Credentials
        ############################
      ERRMSG1
      raise(Awscli::Errors::LoadError.new(message))
    end

    def self.missing_config_file
      message = <<-ERRMSG2.gsub(/^ {8}/, '')
        File Load Error, check if file exists
      ERRMSG2
      raise(Awscli::Errors::LoadError.new(message))
    end

    def self.missing_credentials
      message = <<-ERRMSG3.gsub(/^ {8}/, '')
        MISSING CREDENTIALS
        Add the following to your resource config file:
        #############################
        #Aws Credentials
        #Key value pairs should look like this
        #aws_access_key_id: 022QF06E7MXBSAMPLE
        aws_access_key_id:
        aws_secret_access_key:
        region:
        #
        #End of Aws Credentials
        ############################
      ERRMSG3
      raise(Awscli::Errors::LoadError.new(message))
    end

    def self.invalid_credentials
      message = "Invalid Credentials, Please check your AWS access and secret key id."
      raise(Awscli::Errors::LoadError.new(message))
    end

    def self.invalid_region
      message = "Invalid region found in config file (or) passed as an option , Available Regions are #{Awscli::Instances::REGIONS}"
      raise(Awscli::Errors::LoadError.new(message))
    end

  end
end