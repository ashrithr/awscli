module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class Tags < Thor

        desc "list", "List tags"
        def list
          create_ec2_object
          @ec2.list
        end

        desc "create", "Create tag"
        method_option :key, :aliases => "-k", :required => true, :type => :string, :desc => "key for the tag"
        method_option :resource_id, :aliases => "-r", :required => true, :banner => "RID", :type => :string, :desc => "ID of a resource to tag. For example, ami-1a2b3c4d"
        method_option :value, :aliases => "-v", :required => true, :type => :string, :desc => "Value for a tag. If you don't want the tag to have a value, specify the parameter with no value"
        def create
          create_ec2_object
          @ec2.create options
        end

        desc "delete", "Deletes a specific set of tags from a specific set of resources"
        method_option :key, :aliases => "-k", :required => true, :type => :string, :desc => "key for the tag"
        method_option :resource_id, :aliases => "-r", :required => true, :banner => "RID", :type => :string, :desc => "ID of a resource to tag. For example, ami-1a2b3c4d"
        method_option :value, :aliases => "-v", :required => true, :type => :string, :desc => "Value for a tag. If you don't want the tag to have a value, specify the parameter with no value"
        def delete
          create_ec2_object
          @ec2.delete options
        end

        private

        def create_ec2_object
          puts "ec2 Establishing Connetion..."
          $ec2_conn = if parent_options[:region]
                        Awscli::Connection.new.request_ec2(parent_options[:region])
                      else
                        Awscli::Connection.new.request_ec2
                      end
          puts "ec2 Establishing Connetion... OK"
          @ec2 = Awscli::EC2::Tags.new($ec2_conn)
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::Tags, :tags, 'tags [COMMAND]', 'EC2 Tags Management'

      end
    end
  end
end