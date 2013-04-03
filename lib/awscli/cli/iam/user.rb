module AwsCli
  module CLI
    module IAM
      require 'awscli/cli/iam'
      class User < Thor

        desc 'list', 'list users'
        long_desc <<-DESC
        Lists the users that have the specified path prefix. If there are none, the action returns an empty list.
        DESC
        method_option :path, :aliases => '-p', :default => '/', :desc => 'The path prefix for filtering the results. For example, /division_abc/subdivision_xyz/ would get all users whose path starts with /division_abc/subdivision_xyz/. Default: prints all users'
        # method_option :marker, :aliases => '-m', :desc => 'used to paginate subsequent requests'
        # method_option :maxitems, :alises => '-i', :type => :numeric, :desc => 'limit results to this number per page'
        def list
          create_iam_object
          @iam.list options[:path]
        end

        desc 'create', 'create a user'
        long_desc <<-DESC
        Creates a new user in your AWS account. Optionally adds the user to a group, creates an access key for the user and puts default policy in place.
        DESC
        method_option :user_name, :aliases => '-u', :required => true, :desc => 'name of the user to create (do not include path)'
        method_option :path, :aliases => '-p', :default => '/', :desc => 'optional path to group, defaults to "/"'
        method_option :group, :aliases => '-g', :desc => 'name of a group you want to add the user to'
        method_option :access_key, :aliases => '-k', :type => :boolean, :default => false, :desc => 'if passed, optionally creates an access key for the user'
        method_option :policy, :aliases => '-l', :type => :boolean, :default => false, :desc => 'if set will not create basic set of access rules for the user, should pass --policy-doc if set'
        method_option :policy_doc, :aliases => '-d', :desc => 'path to the json policy document'
        method_option :password, :aliases => '-a', :type => :boolean, :default => false, :desc => 'assign a generated password for the user'
        def create
          if options[:policy]
            abort 'Required --policy-doc, if --policy is passed' unless options[:policy_doc]
          end
          create_iam_object
          @iam.create options
        end

        desc 'delete', 'delete existing user'
        method_option :user_name, :aliases => '-u', :required => true, :desc => 'name of the user to delete (dont include path)'
        method_option :force, :aliases => '-f', :type => :boolean, :default => false, :decs => 'force deletes users login_profile, access_keys, policies if any'
        def delete
          create_iam_object
          @iam.delete options
        end

        desc 'cak', 'create access key for user'
        long_desc <<-DESC
        Creates a new AWS Secret Access Key and corresponding AWS Access Key ID for the specified user. The default status for new keys is Active.
        DESC
        method_option :user_name, :aliases => '-u', :required => true, :desc => 'The user name that the new key will belong to'
        def cak
          create_iam_object
          @iam.create_user_access_key options[:user_name]
        end

        desc 'lak', 'list access keys for a user'
        method_option :user_name, :aliases => '-u', :required => true, :desc => 'The user name to list the access keys for'
        def lak
          create_iam_object
          @iam.list_user_access_keys options[:user_name]
        end

        desc 'dak', 'delete access key for a user'
        method_option :user_name, :aliases => '-u', :required => true, :desc => 'The username to delete the access key for'
        method_option :access_key_id, :aliases => '-a', :required => true, :desc => 'Access key id to delete'
        def dak
          create_iam_object
          @iam.delete_user_access_key options[:user_name], options[:access_key_id]
        end

        desc 'update', 'updates the name and/or the path of the specified user'
        method_option :user_name, :aliases => '-u', :required => true, :desc => 'The user name to update the information for'
        method_option :new_user_name, :aliases => '-n', :banner => 'USERNAME', :desc => 'New name for the user. Include this parameter only if you are changing the users name.'
        method_option :new_path, :aliases => '-p', :banner => 'PATH' , :desc => 'New path for the user. Include this parameter only if you are changing the users path'
        def update
          create_iam_object
          if !options[:new_user_name] and !options[:new_path]
            puts 'Should pass atleast one option to change, either --new-user-name (or) --new-path'
            exit
          end
          @iam.update_user options
        end

        desc 'addtogroup', 'Add an existing user to a group'
        method_option :user_name, :aliases => '-u', :required => true, :desc => 'name of user to add'
        method_option :group_name, :aliases => '-g', :required => true, :desc => 'name of the group'
        def addtogroup
          create_iam_object
          @iam.add_user_to_group options[:user_name], options[:group_name]
        end

        desc 'removefromgroup', 'Remove a user from a group'
        method_option :user_name, :aliases => '-u', :required => true, :desc => 'name of user to remove'
        method_option :group_name, :aliases => '-g', :required => true, :desc => 'name of the group to remove from'
        def removefromgroup
          create_iam_object
          @iam.remove_user_from_group options[:user_name], options[:group_name]
        end

        desc 'listgroups', 'List groups for user'
        method_option :user_name, :aliases => '-u', :required => true, :desc => 'name of the user to list the groups for'
        def listgroups
          create_iam_object
          @iam.list_groups_for_user options[:user_name]
        end

        desc 'passwd [OPTIONS]', 'add/change user password'
        method_option :user_name, :aliases => '-u', :required => true, :desc => 'name of the user to change password for'
        method_option :password, :alases => '-p', :desc => 'password for the user'
        method_option :generate, :aliases => '-g', :type => :boolean, :default => false, :desc => 'generates the password'
        method_option :remove, :aliases => '-r', :type => :boolean, :default => false, :desc => 'remove password for the user'
        def passwd
          create_iam_object
          if options[:remove]
            @iam.remove_password options[:user_name]
          else
            if options[:generate]
              @iam.assign_password options[:user_name], options[:password]
            else
              @iam.generate_password options[:user_name]
            end
          end
        end

        private

        def create_iam_object
          puts 'IAM Establishing Connetion...'
          $iam_conn =  Awscli::Connection.new.request_iam
          puts 'IAM Establishing Connetion... OK'
          @iam = Awscli::Iam::User.new($iam_conn)
        end

        AwsCli::CLI::Iam.register AwsCli::CLI::IAM::User, :user, 'user [COMMAND]', 'IAM User Management'

      end
    end
  end
end