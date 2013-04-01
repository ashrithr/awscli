module AwsCli
  module CLI
    module IAM
      require 'awscli/cli/iam'
      class Roles < Thor

        desc 'list', 'list available roles'
        def list
          create_iam_object
          @iam.list
        end

        desc 'create', 'Creates a new role for your AWS account'
        method_option :role_name, :aliases => '-r', :required => true, :desc => 'name of the role to create'
        method_option :policy_document, :aliases => '-d', :required => true, :banner => 'PATH', :desc => 'path to the policy document that grants an entity permission to assume the role'
        method_option :path, :aliases => '-p', :default => '/', :desc => 'Path to the user If you dont want the role to have a path, set to /'
        def create
          create_iam_object
          @iam.create_role options
        end

        desc 'delete', 'Deletes an existing role from your AWS account'
        method_option :role_name, :aliases => '-r', :required => true, :desc => 'name of the role to delete'
        def delete
          create_iam_object
          @iam.delete_role options[:role_name]
        end

        private

        def create_iam_object
          puts 'IAM Establishing Connetion...'
          $iam_conn =  Awscli::Connection.new.request_iam
          puts 'IAM Establishing Connetion... OK'
          @iam = Awscli::Iam::Roles.new($iam_conn)
        end

        AwsCli::CLI::Iam.register AwsCli::CLI::IAM::Roles, :roles, 'roles [COMMAND]', 'IAM Roles Management'

      end
    end
  end
end