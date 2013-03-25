module AwsCli
  module CLI
    module Sss
      require 'awscli/cli/s3'
      class Directories < Thor

        desc "list", "List S3 buckets"
        def list
          create_s3_object
          @s3.list
        end

        desc "create", "Create an new S3 bucket"
        method_option :key, :aliases => "-k", :type => :string, :required => true, :desc => "name of the bucket to create(name should be globally unique)"
        method_option :public, :aliases => "-p", :type => :boolean, :default => false, :desc => "makes the bucket publicly availble"
        # method_option :x_amz_acl, :aliases => "-x", :type => :string, :desc => "Permissions, must be in ['private', 'public-read', 'public-read-write', 'authenticated-read']"
        def create
          create_s3_object
          @s3.create options
        end

        desc "delete", "Delete existing S3 bucket"
        method_option :key, :aliases => "-k", :type => :string, :required => true, :desc => "name of the bucket to delete"
        def delete
          create_s3_object
          @s3.delete options[:key]
        end

        desc "set_acl", "Change access control list for an S3 bucket"
        method_option :key, :aliases => "-k", :type => :string, :required => true, :desc => "name of the bucket to change acl"
        method_option :acl, :aliases => "-a", :type => :string, :required => true, :desc => "Permissions, must be in ['private', 'public-read', 'public-read-write', 'authenticated-read']"
        def set_acl
          create_s3_object
          @s3.set_acl options[:key], options[:acl]
        end

        desc "get_acl", "Get access control list for an S3 bucket"
        method_option :key, :aliases => "-k", :type => :string, :required => true, :desc => "name of the bucket to get acl"
        def get_acl
          create_s3_object
          @s3.get_acl options[:key]
        end

        desc "get_logging_status", "Get logging status for an S3 bucket"
        method_option :key, :aliases => "-k", :type => :string, :required => true, :desc => "name of the bucket"
        def get_logging_status
          create_s3_object
          @s3.get_logging_status options[:key]
        end

        # desc "set_logging_status", "Change logging status for an S3 bucket"
        # method_option :key, :aliases => "-k", :type => :string, :required => true, :desc => "name of the bucket"
        # method_option :owner, :aliases => "-o", :type => :hash, :banner => "ID:NAME", :desc => "set id and displayname of the owner"
        # method_option :grantee, :aliases => "-g", :type => :hash, :banner => "NAME:ID|EMAIL|URI", :desc => "Grantee hash containing, <Display name of the grantee>: <ID of the grantee (or) Email of the grantee (or) Uri of the group to grant access>"
        # method_option :permission, :aliases => "-p", :type => :string, :desc => "Permission, in [FULL_CONTROL, WRITE, WRITE_ACP, READ, READ_ACP]"
        # def set_logging_status
        #   create_s3_object
        #   (acl ||= []) << options[:grantee] if options[:grantee]
        #   acl << options[:permission] if options[:permission]
        #   logging_status = Hash.new
        #   logging_status['Owner'] = options[:owner] if options[:owner]
        #   logging_status['AccessControlList'] = acl if acl
        #   puts "Empty logging_status will disable logging" if logging_status.nil?
        #   puts "#{logging_status}"
        #   @s3.set_logging_status options[:key], logging_status
        # end

        private

        def create_s3_object
          puts "S3 Establishing Connetion..."
          $s3_conn = Awscli::Connection.new.request_s3
          puts "S3 Establishing Connetion... OK"
          @s3 = Awscli::S3::Directories.new($s3_conn)
        end

        AwsCli::CLI::S3.register AwsCli::CLI::Sss::Directories, :dirs, 'dirs [COMMAND]', 'S3 Directories Management'

      end
    end
  end
end