module AwsCli
  module CLI
    module AS
      require 'awscli/cli/as'
      class Configurations < Thor

        desc "list", "list launch configurations"
        method_option :table, :aliases => "-t", :type => :boolean, :desc => "simple format listing in a table"
        def list
          create_as_object
          @as.list options
        end

        desc "create", "create a new launch configuraiton"
        method_option :id, :aliases => "-n", :banner => "NAME", :required => true, :desc => "name of the launch configuraiton to create"
        method_option :image_id, :aliases => "-i", :banner => "ID", :required => true, :desc => "ami id to use for launch configuration"
        method_option :instance_type, :aliases => "-t", :banner => "TYPE", :default => "m1.small", :desc => "instance type to use for launch configuration (e.g. m1.small)"
        method_option :block_device_mappings, :aliases => "-b", :type => :array , :desc => "<devicename>=<blockdeveice>, see help for how to pass values"
        method_option :key_name, :aliases => "-k", :banner => "KEY", :required => true, :desc => "key_pair to use for launch configuration"
        method_option :security_groups, :aliases => "-s", :type => :array, :required => true, :desc => "security group(s) to use for launch configuration"
        method_option :spot_price, :banner => "PRICE", :desc => "if specified will initialize spot intsances"
        method_option :user_data, :banner => "DATA", :desc => "userdata available to the launched instances"
        method_option :instance_monitoring, :type => :boolean, :default => false, :desc => "whether to enable isntance monitoring, defaults to disabled"
        def create
          create_as_object
          @as.create options
        end

        desc "delete", "delete existing launch configuration"
        method_option :id, :aliases => "-n", :banner => "NAME", :required => true, :desc => "name of the launch configuration to delete"
        def delete
          create_as_object
          @as.delete options[:id]
        end

        private

        def create_as_object
          puts "AS Establishing Connetion..."
          $as_conn =  Awscli::Connection.new.request_as
          puts "AS Establishing Connetion... OK"
          @as = Awscli::As::Configurations.new($as_conn)
        end

        AwsCli::CLI::As.register AwsCli::CLI::AS::Configurations, :cfgs, 'cfgs [COMMAND]', 'Auto Scaling Configurations Management'

      end
    end
  end
end