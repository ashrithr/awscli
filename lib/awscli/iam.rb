require 'json'

module Awscli
  module Iam

    class User
      def initialize(connection)
        @conn = connection
      end

      def list(path)
        users = @conn.list_users('PathPrefix' => path).body['Users']
        Formatador.display_table(users)
      rescue Fog::AWS::IAM::ValidationError
        puts "ValidationError: #{$!}"
      end

      def create(options)
        username = options[:user_name]
        @conn.create_user(username, options[:path] ||= '/')
        puts "Created User: #{username}"
        if options[:password]
          #Assign a password for the user
          generate_password username
        end
        if options[:group]
          #add user to the group
          add_user_to_group username, options[:group]
        end
        if options[:access_key]
          #create a access_key for the user
          create_user_access_key username
        end
        if options[:policy]
          #upload the policy document
          document = options[:policy_doc]
          policy_name = "User-#{username}-Custom"
          #validate json document
          doc_path = File.expand_path(document)
          abort "Invalid file path: #{document}" unless File.exist?(doc_path)
          json_string = File.read(doc_path)
          abort "Invalid JSON format found in the document: #{document}" unless valid_json?(json_string)
          @conn.put_user_policy(username,
                                policy_name,
                                JSON.parse(json_string)   #json parsed to hash
          )
          puts "Added policy: #{policy_name} to user: #{username}"
          puts "Added Policy #{policy_name} from #{document}"
        else
          #create set of basic policy to the user created
          user_arn = @conn.users.get(username).arn
          @conn.put_user_policy(
            username,
            "User#{username}Policy",
            {
              'Statement' => [
                {
                  'Effect' => 'Allow',
                  'Action' => 'iam:*AccessKey*',
                  'Resource' => user_arn
                },
                {
                  'Effect' => 'Allow',
                  'Action' => ['ec2:Describe*', 's3:Get*', 's3:List*'],
                  'Resource' => '*'
                }
              ]
            }
          )
          puts 'User policy for accessing/managing keys of their own and read-access is in place'
        end
      rescue Fog::AWS::IAM::ValidationError
        puts "ValidationError: #{$!}"
      rescue Fog::AWS::IAM::EntityAlreadyExists
        puts "[Error] User Exists: #{$!}"
      rescue Fog::AWS::IAM::NotFound, Fog::AWS::IAM::Error
        puts "[Error]: #{$!}"
      end

      def create_user_access_key(username)
        data = @conn.create_access_key('UserName' => username)
        access_key_id = data.body['AccessKey']['AccessKeyId']
        secret_access_key = data.body['AccessKey']['SecretAccessKey']
        #keystatus = data.body['AccessKey']['Status']
        puts 'Store the following access id and secret key:'
        puts "AccessKey: #{access_key_id}"
        puts "SecretAccessKey: #{secret_access_key}"
      rescue Fog::AWS::IAM::NotFound
        puts "[Error]: #{$!}"
      end

      def list_user_access_keys(username)
        @conn.access_keys(:username => username).table
      rescue Fog::AWS::IAM::NotFound
       puts "[Error]: #{$!}"
      end

      def delete_user_access_key(username, access_key_id)
        @conn.delete_access_key(access_key_id, 'UserName' => username)
        puts "Deleted AccessKey for user: #{username}"
      rescue Fog::AWS::IAM::NotFound
       puts "[Error]: #{$!}"
      end

      def update_user(options)
        opts = Marshal.load(Marshal.dump(options))
        opts.reject! { |k| k == 'user_name' }
        if new_user_name = opts.delete(:new_user_name)
          opts.merge!('NewUserName' => new_user_name)
        end
        if new_path = opts.delete(:new_path)
          opts.merge!('NewPath' => new_path)
        end
        @conn.update_user(options[:user_name], opts)
        puts 'Updated user details'
      rescue Fog::AWS::IAM::EntityAlreadyExists
        puts '[Error] User already exists, pass in a different username'
      rescue Fog::AWS::IAM::ValidationError
        puts "ValidationError: #{$!}"
      end

      def add_user_to_group(username, groupname)
        @conn.add_user_to_group(groupname, username)
        puts "Added user: #{username}, to group: #{groupname}"
      rescue Fog::AWS::IAM::NotFound
        puts "[Error]: #{$!}"
      end

      def remove_user_from_group(username, groupname)
        @conn.remove_user_from_group(groupname, username)
        puts "Removed user: #{username}, from group: #{groupname}"
      rescue Fog::AWS::IAM::NotFound
        puts "[Error]: #{$!}"
      end

      def list_groups_for_user(username)
        groups = @conn.list_groups_for_user(username).body['GroupsForUser']
        Formatador.display_table(groups)
      rescue Fog::AWS::IAM::NotFound
        puts "[Error]: #{$!}"
      end

      def assign_password(username, password)
        @conn.create_login_profile(username, password)
        puts "Assigned user #{username} password: #{password}"
      rescue Fog::AWS::IAM::NotFound, Fog::AWS::IAM::ValidationError
        puts "[Error]: #{$!}"
      rescue Fog::AWS::IAM::Error
        puts "[Error]: #{$!}"
        if $!.to_s =~ /PasswordPolicyViolation/
          #TODO: show password policy, this is not available in fog
          puts 'Password policy is violated, please revisit your password policies'
        end
      end

      def generate_password(username)
        tries ||= 3
        password = ((33..126).map { |i| i.chr }).to_a.shuffle[0..14].join
        @conn.create_login_profile(username, password)
      rescue Fog::AWS::IAM::NotFound, Fog::AWS::IAM::ValidationError
        puts "[Error]: #{$!}"
      rescue Fog::AWS::IAM::Error
        puts "[Error]: #{$!}"
        if $!.to_s =~ /PasswordPolicyViolation/
          #TODO: show password policy, this is not available in fog
          #if password policy is violated, then our generated password might be weak, retry 3 times before failing
          retry if (tries -= 1) > 0
        end
      else
        puts "Assigned password: '#{password}' for user #{username}"
        puts 'Store this password, this cannot be retrieved again'
      end

      def remove_password(username)
        @conn.delete_login_profile(username)
        puts "Deleted login profile for user: #{username}"
      rescue Fog::AWS::IAM::Error, Fog::AWS::IAM::NotFound
        puts "[Error]: #{$!}"
      end

      def delete(options)
        username = options[:user_name]
        user = @conn.users.get(username)
        if user
          if options[:force]
            #ask user to confirm deletion
            if agree('Are you sure you want to delete user and users associated login_profile, access_keys, policies ? ')
              #check if user has login profile
              begin
                @conn.get_login_profile(username)
                user_profile = true
              rescue Fog::AWS::IAM::NotFound
                user_profile = false
              end
              remove_password username if user_profile
              #check if user has access_keys
              access_keys = user.access_keys.map { |access_key| access_key.id }
              unless access_keys.empty?
                #delete access_keys
                access_keys.each do |access_key|
                  delete_user_access_key username, access_key
                end
              end
              #check if user belongs to a group
              groups =  @conn.list_groups_for_user(username).body['GroupsForUser'].map { |k| k['GroupName'] }
              unless groups.empty?
                #delete user_groups
                groups.each do |group|
                  remove_user_from_group username, group
                end
              end
              #check if user has policies
              policies = user.policies.map { |policy| policy.id }
              unless policies.empty?
                policies.each do |policy|
                  @conn.delete_user_policy username, policy
                end
              end
            end
          end
          @conn.delete_user(username)
        else
          abort "No such user: #{username}"
        end
      rescue Fog::AWS::IAM::NotFound, Fog::AWS::IAM::Error
        puts "[Error]: #{$!}"
      else
        puts "Deleted User: #{username}"
      end
    end

    class Group
      def initialize(connection)
        @conn = connection
      end

      def list(path)
        groups = @conn.list_groups('PathPrefix' => path).body['Groups']
        Formatador.display_table(groups)
      rescue Fog::AWS::IAM::ValidationError
        puts "ValidationError: #{$!}"
      end

      def create(groupname, path)
        @conn.create_group(groupname, path ||= '/')
        puts "Created group: #{groupname}"
      rescue Fog::AWS::IAM::ValidationError
        puts "ValidationError: #{$!}"
      rescue Fog::AWS::IAM::EntityAlreadyExists
        puts "[Error] Group Exists: #{$!}"
      end

      def delete(groupname)
        @conn.delete_group(groupname)
        puts "Create group: #{groupname}"
      rescue Fog::AWS::IAM::NotFound
        puts "[Error]: #{$!}"
      end
    end

    class Policies
      def initialize(connection)
        @conn = connection
      end

      def list(options)
        if options[:user_name]
          user = @conn.users.get(options[:user_name])
          abort "[Error]: User not found #{user}" unless user
          user.policies.table
        elsif options[:group_name]
          begin
            grp_policies = @conn.list_group_policies(options[:group_name]).body['PolicyNames'].map { |p| { 'Policy' => p } }
            Formatador.display_table(grp_policies)
          rescue Fog::AWS::IAM::NotFound
            puts "[Error]: #{$!}"
          end
        elsif options[:role_name]
          begin
            role_policies = @conn.list_role_policies(options[:role_name]).body['PolicyNames'].map { |p| {'Policy' => p} }
            Formatador.display_table(role_policies)
          rescue Fog::AWS::IAM::NotFound
            puts "[Error]: #{$!}"
          end
        end
      end

      def add_policy_document(options)
        document = options[:policy_document]
        policyname = options[:policy_name]
        #validate json document
        doc_path = File.expand_path(document)
        abort "Invalid file path: #{file_path}" unless File.exist?(doc_path)
        json_string = File.read(doc_path)
        abort "Invalid JSON format found in the document: #{document}" unless valid_json?(json_string)
        begin
          if options[:user_name]
            @conn.put_user_policy(options[:user_name],
              policyname,
              JSON.parse(json_string)   #json parsed to hash
            )
            puts "Added policy: #{policyname} to user: #{options[:user_name]}"
          elsif options[:group_name]
            @conn.put_group_policy(option[:group_name],
              policyname,
              JSON.parse(json_string)
            )
            puts "Added policy: #{policyname} to group: #{options[:group_name]}"
          elsif options[:role_name]
            @conn.put_role_policy(options[:role_name],
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

      def delete_policy(options)
        if options[:user_name]
          @conn.delete_user_policy(options[:user_name], options[:policy_name])
        elsif options[:group_name]
          @conn.delete_group_policy(options[:group_name], options[:policy_name])
        elsif options[:role_name]
          @conn.delete_role_policy(options[:role_name], options[:policy_name])
        end
        puts "Deleted Policy #{options[:policy_name]}"
      rescue Fog::AWS::IAM::NotFound
        puts "[Error]: #{$!}"
      rescue Fog::AWS::IAM::Error
        puts "[Error]: #{$!}"
      end

      def valid_json?(json_string)
        JSON.parse(json_string)
        return true
      rescue JSON::ParserError
        return false
      end
    end

    class Roles
      def initialize(connection)
        @conn = connection
      end

      def list
        roles = @conn.list_roles.body['Roles']
        Formatador.display_table(roles, %w(Arn RoleName Path RoleId))
      end

      def create_role(rolename, document, path)
        #TODO: Build document in line from options use iam-rolecreate as reference
        doc_path = File.expand_path(document)
        abort "Invalid file path: #{file_path}" unless File.exist?(doc_path)
        json_string = File.read(doc_path)
        abort "Invalid JSON format found in the document: #{document}" unless valid_json?(json_string)
        @conn.create_role(rolename, JSON.parse(json_string), path)
        # Example document, AssumeRolePolicyDocument={"Version":"2008-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":["ec2.amazonaws.com"]},"Action":["sts:AssumeRole"]}]}
        puts "Created role: #{rolename}"
      rescue Fog::AWS::IAM::Error
        puts "[Error]: #{$!}"
      end

      def delete_role(rolename)
        @conn.delete_role(rolename)
        puts "Deleted Role #{rolename}"
      rescue Fog::AWS::IAM::NotFound, Fog::AWS::IAM::Error
        if $!.to_s =~ /must remove roles from instance profile first/
          puts "[Error]: #{$!}"
          profile = @conn.list_instance_profiles_for_role('test').body['InstanceProfiles'].map { |k| k['InstanceProfileName'] }
          puts "Associated instance profile name: #{profile.to_s}, delete the instance profile using `awscli iam profiles delete-role --profile-name=NAME --role-name=NAME`"
        else
          puts "[Error]: #{$!}"
        end
      end

      def valid_json?(json_string)
        # => validates json document
        JSON.parse(json_string)
        return true
      rescue JSON::ParserError
        return false
      end
    end

    class Profiles
      def initialize(connection)
        @conn = connection
      end

      def list
        profiles = @conn.list_instance_profiles.body['InstanceProfiles']
        Formatador.display_table(profiles, %w(Arn InstanceProfileName InstanceProfileId Path Roles))
      end

      def list_for_role(rolename)
        profiles = @conn.list_instance_profiles_for_role(rolename).body['InstanceProfiles']
        Formatador.display_table(profiles, %w(Arn InstanceProfileName InstanceProfileId Path Roles))
      rescue Fog::AWS::IAM::NotFound, Fog::AWS::IAM::Error
        puts "[Error]: #{$!}"
      end

      def remove_role_from_instance_profile(rolename, profilename)
        @conn.remove_role_from_instance_profile(rolename, profilename)
      rescue Fog::AWS::IAM::NotFound, Fog::AWS::IAM::Error
        puts "[Error]: #{$!}"
      end

      def create(profilename, path)
        @conn.create_instance_profile(profilename, path)
      rescue Fog::AWS::IAM::NotFound, Fog::AWS::IAM::Error
        puts "[Error]: #{$!}"
      end

      def delete(profilename)
        @conn.delete_instance_profile(profilename)
      rescue Fog::AWS::IAM::NotFound, Fog::AWS::IAM::Error
        puts "[Error]: #{$!}"
      end
    end

  end
end