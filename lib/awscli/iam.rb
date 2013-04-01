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

      def add_policy options
      end

      def add_policy_document username, policyname, document
        #validate json document
        doc_path = File.expand_path(document)
        abort "Invalid file path: #{file_path}" unless File.exist?(doc_path)
        json_string = File.read(doc_path)
        abort "Invlaud JSON format found in the document: #{document}" unless valid_json?(json_string)
        begin
          @@conn.put_user_policy(username,
            policyname,
            JSON.parse(json_string)   #json parsed to hash
          )
          puts "Added policy: #{policyname} to user: #{username}"
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

      def list_policies username
        user = @@conn.users.get(username)
        abort "[Error]: User not found #{username}" unless user
        user.policies.table
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

      def delete username
        begin
          @@conn.delete_user(username)
          puts "Deleted User: #{username}"
        rescue Fog::AWS::IAM::NotFound
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

      def create
      end

      def delete
      end
    end

  end
end