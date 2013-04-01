module AwsCli
  module CLI
    module IAM
      require 'awscli/cli/iam'
      class Group < Thor

        desc 'list', 'list users'
        long_desc <<-DESC
        Lists the users that have the specified path prefix. If there are none, the action returns an empty list.
        DESC
        method_option :path, :aliases => '-p', :default => '/', :desc => 'The path prefix for filtering the results. For example, /division_abc/subdivision_xyz/ would get all users whose path starts with /division_abc/subdivision_xyz/. Default: prints all groups'
        def list
          create_iam_object
          @iam.list options[:path]
        end

        private

        def create_iam_object
          puts 'IAM Establishing Connetion...'
          $iam_conn =  Awscli::Connection.new.request_iam
          puts 'IAM Establishing Connetion... OK'
          @iam = Awscli::Iam::Group.new($iam_conn)
        end

        AwsCli::CLI::Iam.register AwsCli::CLI::IAM::Group, :group, 'group [COMMAND]', 'IAM Group Management'

      end
    end
  end
end