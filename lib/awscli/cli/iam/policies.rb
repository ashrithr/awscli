module AwsCli
  module CLI
    module IAM
      require 'awscli/cli/iam'
      class Policies < Thor

        desc 'add [OPTIONS]', 'Adds (or updates) a policy document associated with the specified user/group'
        long_desc <<-DESC
        Creates a policy based on the information you provide and attaches the policy to the specified user/group.  The command accepts a file containing the policy.
        Use http://awspolicygen.s3.amazonaws.com/policygen.html to generate policy documents
        DESC
        method_option :user_name, :aliases => '-u', :banner => 'NAME', :desc => 'Name of the user the policy is for'
        method_option :group_name, :aliases => '-g', :banner => 'NAME', :desc => 'Name of the group tha policy is for'
        method_option :policy_name, :aliases => '-p', :required => true, :banner => 'NAME', :desc => 'Name you want to assign the policy'
        method_option :policy_document, :aliases => '-f', :required => true, :banner => 'PATH', :desc => 'Path and name of the file containing the policy, Use http://awspolicygen.s3.amazonaws.com/policygen.html to generate policy documents'
        def add
          create_iam_object
          if !options[:user_name] and !options[:group_name]
            puts 'should pass either --user-name or --group-name'
            exit
          end
          @iam.add_policy_document options
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

        desc 'list [OPTIONS]' , 'list policies for a user/group pass respective options'
        method_option :user_name, :aliases => '-u', :desc => 'name of the user to list policies for'
        method_option :group_name, :aliases => '-g', :desc => 'name of the gourp to list policies for'
        def list
          if !options[:user_name] and !options[:group_name]
            puts 'should pass either --user-name or --group-name'
            exit
          end
          create_iam_object
          @iam.list options
        end

        desc 'delete [OPTIONS]', 'delete policy associated with a user/group'
        method_option :user_name, :aliases => '-u', :desc => 'name of the user to delete policies for'
        method_option :group_name, :aliases => '-g', :desc => 'name of the gourp to delete policies for'
        method_option :policy_name, :aliases => '-f', :required => true, :desc => 'name of the policy to delete'
        def delete
          if !options[:user_name] and !options[:group_name]
            puts 'should pass either --user-name or --group-name'
            exit
          end
          create_iam_object
          @iam.delete_policy options
        end

        private

        def create_iam_object
          puts 'IAM Establishing Connetion...'
          $iam_conn =  Awscli::Connection.new.request_iam
          puts 'IAM Establishing Connetion... OK'
          @iam = Awscli::Iam::Policies.new($iam_conn)
        end

        AwsCli::CLI::Iam.register AwsCli::CLI::IAM::Policies, :policies, 'policies [COMMAND]', 'IAM Policies Management'

      end
    end
  end
end