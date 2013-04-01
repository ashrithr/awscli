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

        desc 'create', 'create a new group'
        method_option :group_name, :aliases => '-g', :required => true, :desc => 'name of the group to create (do not include path)'
        method_option :path, :aliases => '-p', :default => '/', :desc => 'optional path to group, defaults to "/"'
        def create
          create_iam_object
          @iam.create options[:group_name], options[:path]
        end

        desc 'delete', 'delete existing group'
        method_option :group_name, :aliases => '-g', :required => true, :desc => 'name of the group to delete'
        def delete
          create_iam_object
          @iam.delete options[:group_name]
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