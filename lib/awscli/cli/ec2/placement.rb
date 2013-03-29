module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class Placement < Thor

        desc "list", "List Placement Groups"
        def list
          create_ec2_object
          @ec2.list
        end

        desc "create", "Create a new placement group"
        method_option :name, :aliases => "-n", :required => true, :type => :string, :desc => "Name of the placement group"
        method_option :strategy, :aliases => "-s", :type => :string, :default => "cluster", :desc => "Placement group strategy. Valid options in ['cluster']"
        def create
          create_ec2_object
          @ec2.create options
        end

        desc "delete", "Delete a placement group that you own"
        method_option :name, :aliases => "-n", :required => true, :type => :string, :desc => "Name of the placement group"
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
          @ec2 = Awscli::EC2::Placement.new($ec2_conn)
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::Placement, :place, 'place [COMMAND]', 'EC2 Placement Management'

      end
    end
  end
end