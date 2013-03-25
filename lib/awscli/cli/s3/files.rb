module AwsCli
  module CLI
    module Sss
      require 'awscli/cli/s3'
      class Files < Thor


        private

        def create_ec2_object
          puts "S3 Establishing Connetion..."
          $s3_conn = Awscli::Connection.new.request_s3
          puts "S3 Establishing Connetion... OK"
          @s3 = Awscli::S3::Files.new($s3_conn)
        end

        AwsCli::CLI::S3.register AwsCli::CLI::Sss::Files, :files, 'files [COMMAND]', 'S3 Files Management'

      end
    end
  end
end