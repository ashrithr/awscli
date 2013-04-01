require 'json'

module Awscli
  module Iam

    class User
      def initialize connection, options = {}
        @@conn = connection
      end

      def list path
        begin
          users = @@conn.list_users('PathPrefix' => path).body['Users']
          Formatador.display_table(users)
        rescue Fog::AWS::IAM::ValidationError
          puts "ValidationError: #{$!}"
        end
      end

      def create username, path
        # TODO: Include other options as well
        begin
          @@conn.create_user(username, path ||= '/')
          puts "Created User: #{username}"
        rescue Fog::AWS::IAM::ValidationError
          puts "ValidationError: #{$!}"
        rescue Fog::AWS::IAM::EntityAlreadyExists
          puts "[Error] User Exists: #{$!}"
        end
      end

      def create_user_access_key username
        begin
          data = @@conn.create_access_key('UserName' => username)
          accesskeyid = data.body['AccessKey']['AccessKeyId']
          secretaccesskey = data.body['AccessKey']['SecretAccessKey']
          keystatus = data.body['AccessKey']['Status']
          puts 'Store the following access id and secret key:'
          puts "AccessKey: #{accesskeyid}"
          puts "SecretAccessKey: #{secretaccesskey}"
        rescue Fog::AWS::IAM::NotFound
          puts "[Error]: #{$!}"
        end
      end

      def list_user_access_keys username
        begin
          @@conn.access_keys(:username => username).table
        rescue Fog::AWS::IAM::NotFound
         puts "[Error]: #{$!}"
        end
      end

      def delete_user_access_key username, accesskeyid
        begin
          @@conn.delete_access_key(accesskeyid, 'UserName' => username)
          puts "Deleted AccessKey for user: #{username}"
        rescue Fog::AWS::IAM::NotFound
         puts "[Error]: #{$!}"
        end
      end

      def update_user options
        opts = Marshal.load(Marshal.dump(options))
        opts.reject! { |k| k == 'user_name' }
        if new_user_name = opts.delete(:new_user_name)
          opts.merge!('NewUserName' => new_user_name)
        end
        if new_path = opts.delete(:new_path)
          opts.merge!('NewPath' => new_path)
        end
        begin
          @@conn.update_user(options[:user_name], opts)
          puts 'Updated user details'
        rescue Fog::AWS::IAM::EntityAlreadyExists
          puts '[Error] User already exists, pass in a different username'
        rescue Fog::AWS::IAM::ValidationError
          puts "ValidationError: #{$!}"
        end
      end

      def add_user_to_group username, groupname
        begin
          @@conn.add_user_to_group(groupname, username)
          puts "Added user: #{username}, to group: #{groupname}"
        rescue Fog::AWS::IAM::NotFound
          puts "[Error]: #{$!}"
        end
      end

      def remove_user_from_group username, groupname
        begin
          @@conn.remove_user_from_group(groupname, username)
          puts "Removed user: #{username}, from group: #{groupname}"
        rescue Fog::AWS::IAM::NotFound
          puts "[Error]: #{$!}"
        end
      end

      def list_groups_for_user username
        begin
          groups = @@conn.list_groups_for_user(username).body['GroupsForUser']
          Formatador.display_table(groups)
        rescue Fog::AWS::IAM::NotFound => e
          puts "[Error]: #{$!}"
        end
      end

      def add_policy options
      end

      def assign_password username, password, autogenpwd = false
        password = if autogenpwd
          # generate a random password
          ((33..126).map { |i| i.chr }).to_a.shuffle[0..14].join
        end
        begin
          @@conn.create_login_profile(username, password)
          puts "Assigned user #{username} password: #{password}"
        rescue Fog::AWS::IAM::NotFound, Fog::AWS::IAM::ValidationError
          puts "[Error]: #{$!}"
        rescue Fog::AWS::IAM::Error
          puts "[Error]: #{$!}"
          if $!.to_s =~ /PasswordPolicyViolation/
            #TODO: show password policy, this is not available in fog
            puts "Revisit your password polocies"
          end
        end
      end

      def remove_password username
        begin
          @@conn.delete_login_profile(username)
        rescue Fog::AWS::IAM::Error, Fog::AWS::IAM::NotFound
          puts "[Error]: #{$!}"
        end
      end

      def delete username
        begin
          @@conn.delete_user(username)
          puts "Deleted User: #{username}"
        rescue Fog::AWS::IAM::NotFound
          puts "[Error]: #{$!}"
        end
      end
    end

    class Group
      def initialize connection, options = {}
        @@conn = connection
      end

      def list path
        begin
          groups = @@conn.list_groups('PathPrefix' => path).body['Groups']
          Formatador.display_table(groups)
        rescue Fog::AWS::IAM::ValidationError
          puts "ValidationError: #{$!}"
        end
      end

      def create groupname, path
        begin
          @@conn.create_group(groupname, path ||= '/')
          puts "Created group: #{groupname}"
        rescue Fog::AWS::IAM::ValidationError
          puts "ValidationError: #{$!}"
        rescue Fog::AWS::IAM::EntityAlreadyExists
          puts "[Error] Group Exists: #{$!}"
        end
      end

      def delete groupname
        begin
          @@conn.delete_group(groupname)
          puts "Create group: #{groupname}"
        rescue Fog::AWS::IAM::NotFound
          puts "[Error]: #{$!}"
        end
      end
    end

    class Policies
      def initialize connection, options = {}
        @@conn = connection
      end

      def list options
        if options[:user_name]
          user = @@conn.users.get(options[:user_name])
          abort "[Error]: User not found #{user_name}" unless user
          user.policies.table
        elsif options[:group_name]
          begin
            grp_policies = @@conn.list_group_policies(options[:group_name]).body['PolicyNames'].map { |p| { 'Policy' => p } }
            Formatador.display_table(grp_policies)
          rescue Fog::AWS::IAM::NotFound
            puts "[Error]: #{$!}"
          end
        elsif options[:role_name]
          begin
            role_policies = @@conn.list_role_policies(options[:role_name]).body['PolicyNames'].map { |p| {'Policy' => p} }
            Formatador.display_table(role_policies)
          rescue Fog::AWS::IAM::NotFound
            puts "[Error]: #{$!}"
          end
        end
      end

      def add_policy_document options
        document = options[:policy_document]
        policyname = options[:policy_name]
        #validate json document
        doc_path = File.expand_path(document)
        abort "Invalid file path: #{file_path}" unless File.exist?(doc_path)
        json_string = File.read(doc_path)
        abort "Invalid JSON format found in the document: #{document}" unless valid_json?(json_string)
        begin
          if options[:user_name]
            @@conn.put_user_policy(options[:user_name],
              policyname,
              JSON.parse(json_string)   #json parsed to hash
            )
            puts "Added policy: #{policyname} to user: #{options[:user_name]}"
          elsif options[:group_name]
            @@conn.put_group_policy(option[:group_name],
              policyname,
              JSON.parse(json_string)
            )
            puts "Added policy: #{policyname} to group: #{options[:group_name]}"
          elsif options[:role_name]
            @@conn.put_role_policy(options[:role_name],
              policyname,
              JSON.parse(json_string)
            )
          end
          puts "Added Policy #{policyname} from #{document}"
        rescue Fog::AWS::IAM::NotFound
          puts "[Error]: #{$!}"
        rescue Fog::AWS::IAM::Error
          puts "[Error]: #{$!}"
        end

        # => Example Documents

        # iam.put_user_policy(username, 'UserKeyPolicy', {
        #   'Statement' => [
        #     'Effect' => 'Allow',
        #     'Action' => 'iam:*AccessKey*',
        #     'Resource' => arn
        #   ]
        # })

        # iam.put_user_policy(username, 'UserS3Policy', {
        #   'Statement' => [
        #     {
        #       'Effect' => 'Allow',
        #       'Action' => ['s3:*'],
        #       'Resource' => [
        #         "arn:aws:s3:::#{bucket_name}",
        #         "arn:aws:s3:::#{bucket_name}/*"
        #       ]
        #     }, {
        #       'Effect' => 'Deny',
        #       'Action' => ['s3:*'],
        #       'NotResource' => [
        #         "arn:aws:s3:::#{bucket_name}",
        #         "arn:aws:s3:::#{bucket_name}/*"
        #       ]
        #     }
        #   ]
        # })
      end

      def delete_policy options
        begin
          if options[:user_name]
            @@conn.delete_user_policy(options[:user_name], options[:policy_name])
          elsif options[:group_name]
            @@conn.delete_group_policy(options[:group_name], options[:policy_name])
          elsif options[:role_name]
            @@conn.delete_role_policy(options[:role_name], options[:policy_name])
          end
          puts "Deleted Policy #{options[:policy_name]}"
        rescue Fog::AWS::IAM::NotFound
          puts "[Error]: #{$!}"
        rescue Fog::AWS::IAM::Error
          puts "[Error]: #{$!}"
        end
      end

      def valid_json? json_string
        JSON.parse(json_string)
        return true
      rescue JSON::ParserError
        return false
      end
    end

    class Roles
      def initialize connection, options = {}
        @@conn = connection
      end

      def list
        roles = @@conn.list_roles.body['Roles']
        Formatador.display_table(roles, ['Arn', 'RoleName', 'Path', 'RoleId'])
      end

      def create_role rolename, document, path
        #TODO: Build document in line from options use iam-rolecreate as reference
        doc_path = File.expand_path(document)
        abort "Invalid file path: #{file_path}" unless File.exist?(doc_path)
        json_string = File.read(doc_path)
        abort "Invalid JSON format found in the document: #{document}" unless valid_json?(json_string)
        begin
          @@conn.create_role(rolename, JSON.parse(json_string), path)
          # Example document, AssumeRolePolicyDocument={"Version":"2008-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":["ec2.amazonaws.com"]},"Action":["sts:AssumeRole"]}]}
          puts "Created role: #{rolename}"
        rescue Fog::AWS::IAM::Error
          puts "[Error]: #{$!}"
        end
      end

      def delete_role rolename
        begin
          @@conn.delete_role(rolename)
          puts "Deleted Role #{rolename}"
        rescue Fog::AWS::IAM::NotFound, Fog::AWS::IAM::Error
          if $!.to_s =~ /must remove roles from instance profile first/
            puts "[Error]: #{$!}"
            profile = @@conn.list_instance_profiles_for_role('test').body['InstanceProfiles'].map { |k| k['InstanceProfileName'] }
            puts "Associated instance profile name: #{profile.to_s}, delete the instance profile using `awscli iam profiles delete-role --profile-name=NAME --role-name=NAME`"
          else
            puts "[Error]: #{$!}"
          end
        end
      end

      def valid_json? json_string
        # => validates json document
        JSON.parse(json_string)
        return true
      rescue JSON::ParserError
        return false
      end
    end

    class Profiles
      def initialize connection, options = {}
        @@conn = connection
      end

      def list
        profiles = @@conn.list_instance_profiles.body['InstanceProfiles']
        Formatador.display_table(profiles, ['Arn', 'InstanceProfileName', 'InstanceProfileId', 'Path', 'Roles'])
      end

      def list_for_role rolename
        begin
          profiles = @@conn.list_instance_profiles_for_role(rolename).body['InstanceProfiles']
          Formatador.display_table(profiles, ['Arn', 'InstanceProfileName', 'InstanceProfileId', 'Path', 'Roles'])
        rescue Fog::AWS::IAM::NotFound, Fog::AWS::IAM::Error
          puts "[Error]: #{$!}"
        end
      end

      def remove_role_from_instance_profile rolename, profilename
        begin
          @@conn.remove_role_from_instance_profile(rolename, profilename)
        rescue Fog::AWS::IAM::NotFound, Fog::AWS::IAM::Error
          puts "[Error]: #{$!}"
        end
      end

      def create profilename, path
        begin
          @@conn.create_instance_profile(profilename, path)
        rescue Fog::AWS::IAM::NotFound, Fog::AWS::IAM::Error
          puts "[Error]: #{$!}"
        end
      end

      def delete profilename
        begin
          @@conn.delete_instance_profile(profilename)
        rescue Fog::AWS::IAM::NotFound, Fog::AWS::IAM::Error
          puts "[Error]: #{$!}"
        end
      end
    end

  end
end