module Awscli
  module S3

    class Files
      def initialize connection, options = {}
        @@conn = connection
      end
    end

    class Directories
      def initialize connection, options = {}
        @@conn = connection
      end

      def list
        @@conn.directories.table
      end

      def create options
        dir = @@conn.directories.create(options)
        puts "Create bucket: #{dir.key}"
      end

      def delete dir_name
        dir = @@conn.directories.get(dir_name)
        abort "Cannot find bucket #{dir_name}" unless dir
        dir.destroy
        puts "Deleted Bucket: #{dir_name}"
      end

      def get_acl dir_name
        dir = @@conn.directories.get(dir_name)
        abort "Cannot find bucket #{dir_name}" unless dir
        puts dir.acl
      end

      def set_acl dir_name, acl
        dir = @@conn.directories.get(dir_name)
        abort "Cannot find bucket #{dir_name}" unless dir
        dir.acl = acl
        puts "Acl has been changed to #{acl}"
      end

      def get_logging_status dir_name
        puts @@conn.get_bucket_logging(dir_name).body['BucketLoggingStatus']
      end

      def set_logging_status dir_name, logging_status = {}
        @@conn.put_bucket_logging dir_name, logging_status
      end
    end

  end
end