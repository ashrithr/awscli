module AwsCli
  module CLI
    module IAM
      require 'awscli/cli/iam'
      class Profiles < Thor

        desc 'list', 'list available isntance profiles, specify role to list profiles specific to that role'
        method_option :role, :aliases => '-r', :banner => 'NAME', :desc => 'role name to list instance profiles for'
        def list
          create_iam_object
          if options[:role]
            @iam.list_for_role options[:role]
          else
            @iam.list
          end
        end

        desc 'create', 'Creates a new instance profile'
        method_option :profile_name, :aliases => '-p', :banner => 'NAME', :required => true, :desc => 'name of the isntance profile to create'
        method_option :path, :aliases => '-p', :default => '/', :desc => 'optional path to group, defaults to /'
        def create
          create_iam_object
          @iam.create options[:profile_name], options[:path]
        end

        desc 'delete', 'Deletes an existing instance profile from your AWS account'
        method_option :profile_name, :aliases => '-p', :banner => 'NAME', :required => true, :desc => 'name of the isntance profile to create'
        def delete
          create_iam_object
          @iam.delete options[:profile_name]
        end

        desc 'delete_role', 'Removes a role from a instance profile'
        method_option :profile_name, :aliases => '-p', :banner => 'NAME', :required => true, :desc => 'Name of the instance profile to update'
        method_option :role_name, :aliases => '-r', :banner => 'NAME', :required => true, :desc => 'Name of the role to remove'
        def delete_role
          create_iam_object
          @iam.remove_role_from_instance_profile options[:profile_name], options[:role_name]
        end

        private

        def create_iam_object
          puts 'IAM Establishing Connetion...'
          $iam_conn =  Awscli::Connection.new.request_iam
          puts 'IAM Establishing Connetion... OK'
          @iam = Awscli::Iam::Profiles.new($iam_conn)
        end

        AwsCli::CLI::Iam.register AwsCli::CLI::IAM::Profiles, :profiles, 'profiles [COMMAND]', 'IAM Profiles Management'

      end
    end
  end
end