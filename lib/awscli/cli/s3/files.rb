module AwsCli
  module CLI
    module Sss
      require 'awscli/cli/s3'
      class Files < Thor

        desc "list", "list objects(files) in a bucket"
        method_option :bucket_name, :aliases => "-b", :required => true, :desc => "bucket name to print the contents from"
        def list
          create_s3_object
          @s3.list options[:bucket_name]
        end

        desc "put", "put a file into a bucket"
        method_option :bucket_name, :aliases => "-b", :required => true, :desc => "name of the bucket to upload the file to"
        method_option :file_path, :aliases => "-p", :required => true, :desc => "local file path"
        def put
          create_s3_object
          @s3.upload_file options[:bucket_name], options[:file_path]
        end

        desc "put_rec", "put a directory recusively into a specified bucket using multiple threads"
        method_option :bucket_name, :aliases => "-b", :required => true, :desc => "name of the bucker to upload the dir to"
        method_option :dir_path, :aliases => "-p", :required => true, :desc => "path of the dir to upload"
        method_option :dest_path, :aliases => "-d", :desc => "optionally specify destination directory path to create"
        method_option :thread_count, :aliases => "-t", :type => :numeric, :default => 5, :desc => "number of threads to use to upload files"
        method_option :public, :type => :boolean, :default => false, :desc => "set ACL of files to public"
        def put_rec
          create_s3_object
          @s3.upload_file_rec options
        end

        desc "get", "get a file from a bucket"
        method_option :bucket_name, :aliases => "-b", :required => true, :desc => "name of the bucket to download the file from"
        method_option :file_name, :aliases => "-f", :required => true, :desc => "name of file to download"
        method_option :local_path, :aliases => "-p", :required => true, :desc => "local fs path, where to download the file to"
        def get
          create_s3_object
          @s3.download_file options[:bucket_name], options[:file_name], options[:local_path]
        end

        desc "delete", "delete a file from a bucket"
        method_option :bucket_name, :aliases => "-b", :required => true, :desc => "name of the bucket to download the file from"
        method_option :file_name, :aliases => "-f", :required => true, :desc => "name of file to download"
        def delete
          create_s3_object
          @s3.delete_file options[:bucket_name], options[:file_name]
        end

        desc "copy", "copy object from one bucket to another"
        method_option :source_bucket, :aliases => "-s", :required => true, :desc => "source bucket name from where to copy the file"
        method_option :source_file, :aliases => "-f", :required => true, :desc => "source file name to copy"
        method_option :dest_bucket, :aliases => "-d", :required => true, :desc => "destination bucket name to copy the file to"
        method_option :dest_file, :alises => "-r", :required => true, :desc => "destination file name"
        def copy
          create_s3_object
          @s3.copy_file options[:source_bucket], options[:source_file], options[:dest_bucket], options[:dest_file]
        end

        desc "public_url", "show the public url of a file"
        method_option :bucket_name, :aliases => "-b", :required => true, :desc => "name of the bucket to download the file from"
        method_option :file_name, :aliases => "-f", :required => true, :desc => "name of file to download"
        def public_url
          create_s3_object
          @s3.get_public_url options[:bucket_name], options[:file_name]
        end


        private

        def create_s3_object
          puts "S3 Establishing Connetion..."
          $s3_conn = if parent_options[:region]
                        Awscli::Connection.new.request_s3(parent_options[:region])
                      else
                        Awscli::Connection.new.request_s3
                      end
          puts "S3 Establishing Connetion... OK"
          @s3 = Awscli::S3::Files.new($s3_conn)
        end

        AwsCli::CLI::S3.register AwsCli::CLI::Sss::Files, :files, 'files [COMMAND]', 'S3 Files Management'

      end
    end
  end
end