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
        Creates a new user in your AWS account. Optionally adds the user to one or more groups, and creates an access key for the user.
        DESC
        method_option :user_name, :aliases => '-u', :required => true, :desc => 'name of the user to create (do not include path)'
        method_option :path, :aliases => '-p', :defualt => '/', :desc => 'optional path to group, defaults to "/"'
        method_option :group, :aliases => '-g', :desc => 'name of a group you want to add the user to'
        method_option :access_key, :alises => '-k', :desc => 'creates an access key for the user'
        def create
          create_iam_object
          @iam.create options[:user_name], options[:path]
        end

        desc 'delete', 'delete existing user'
        method_option :user_name, :aliases => '-u', :required => true, :desc => 'name of the user to delete (dont include path)'
        def delete
          create_iam_object
          @iam.delete options[:user_name]
        end

        desc 'addpolicydoc', 'Adds (or updates) a policy document associated with the specified user'
        long_desc <<-DESC
        Creates a policy based on the information you provide and attaches the policy to the specified user.  The command accepts a file containing the policy.
        Use http://awspolicygen.s3.amazonaws.com/policygen.html to generate policy documents
        DESC
        method_option :user_name, :aliases => '-u', :required => true, :banner => 'NAME', :desc => 'Name of the user the policy is for'
        method_option :policy_name, :aliases => '-p', :required => true, :banner => 'NAME', :desc => 'Name you want to assign the policy'
        method_option :policy_document, :aliases => '-f', :required => true, :banner => 'PATH', :desc => 'Path and name of the file containing the policy, Use http://awspolicygen.s3.amazonaws.com/policygen.html to generate policy documents'
        def addpolicydoc
          create_iam_object
          @iam.add_policy_document options[:user_name], options[:policy_name], options[:policy_document]
        end

        # desc 'addpolicy', 'Creates a policy based on the information you provide and attaches the policy to the specified user'
        # long_desc <<-DESC
        # Use this command if you need a simple policy with no conditions, and you don't want to write the policy yourself. If you need a policy with conditions, you must write the policy yourself and upload it with addpolicydoc.
        # DESC
        # method_option :user_name, :aliases => '-u', :required => true, :desc => 'Name of the user the policy is for'
        # method_option :policy_name, :aliases => '-p', :required => true, :desc => 'Name you want to assign the policy'
        # method_option :effect, :aliases => '-e', :required => true, :desc => 'The value for the policys Effect element. Specifies whether the policy results in an allow or a deny, Valid Values: Allow | Deny'
        # method_option :action, :aliases => '-a', :type => :array, :required => true, :desc => 'The value for the policys Action element. Specifies the service and action you want to allow or deny permission to. For example: -a iam:ListAccessKeys. You can use wildcards, and you can specify more than one -a Action option in the request'
        # method_option :resouce_name, :aliases => '-r', :type => :array, :required => true, :desc => 'The value for the policys Resource element. Specifies the Amazon Resource Name (ARN) for the resource (or resources) the policy applies to. You can use wildcards, and you can specify more than one -r AMAZON RESOURCE NAME option in the request'
        # method_option :output, :aliases => '-o', :type => :boolean, :default => false, :desc => 'Causes the output to include the JSON policy document that IAM created for you'
        # def addpolicy
        #   create_iam_object
        #   @iam.add_policy options
        # end

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

        desc 'passwd', 'add/change user password'
        method_option :user_name, :aliases => '-u', :required => true, :desc => 'name of the user to change password for'
        method_option :password, :alases => '-p', :desc => 'password for the user'
        method_option :genereate, :aliases => '-g', :type => :boolean, :default => false, :desc => 'generates the password'
        def passwd
          create_iam_object
          @iam.assign_password options[:user_name], options[:password], options[:genereate]
        end

        desc 'listpolicies' , 'list policies for a user'
        method_option :user_name, :aliases => '-u', :required => true, :desc => 'name of the user to list policies for'
        def listpolicies
          create_iam_object
          @iam.list_policies options[:user_name]
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