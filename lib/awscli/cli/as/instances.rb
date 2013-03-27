module AwsCli
  module CLI
    module AS
      require 'awscli/cli/as'
      class Instances < Thor

        desc "list [OPTIONS]", "list instances in auto scaling groups"
        def list
          create_as_object
          @as.list
        end

        desc "terminate", "termiante a particular instance from auto scaling group"
        method_option :id, :aliases => "-i", :required => true, :desc => "instance id to terminate"
        method_option :should_decrement_desired_capacity, :aliases => "-d", :type => :boolean, :default => false, :desc => " Specifies whether (true) or not (false) terminating this instance should also decrement the size of the AutoScalingGroup."
        def terminate
          create_as_object
          @as.terminate options[:id], options[:should_decrement_desired_capacity]
        end

        private
        def create_as_object
          puts "AS Establishing Connetion..."
          $as_conn =  Awscli::Connection.new.request_as
          puts "AS Establishing Connetion... OK"
            @as = Awscli::As::Instances.new($as_conn)
        end

        AwsCli::CLI::As.register AwsCli::CLI::AS::Instances, :instances, 'instances [COMMAND]', 'Auto Scaling Instances Management'

      end
    end
  end
end