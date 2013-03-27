module AwsCli
  module CLI
    module AS
      require 'awscli/cli/as'
      class Policies < Thor

        desc "list [OPTIONS]", "list auto scaling policies"
        def list
          create_as_object
          @as.list
        end

        desc "create", "create a policy for auto scaling group"
        method_option :id, :aliases => "-n", :banner => "NAME", :required => true, :desc => "The name of the policy you want to create"
        method_option :adjustment_type, :aliases => "-a", :required => true, :desc => "Specifies whether the scaling_adjustment is an absolute number or a percentage of the current capacity, Valid values are ChangeInCapacity, ExactCapacity, and PercentChangeInCapacity."
        method_option :auto_scaling_group_name, :aliases => "-g", :required => true, :desc => "name of the auto scaling group"
        method_option :scaling_adjustment, :aliases => "-s", :type => :numeric, :required => true, :desc => "The number of instances by which to scale. AdjustmentType determines the interpretation of this number (e.g., as an absolute number or as a percentage of the existing Auto Scaling group size). A positive increment adds to the current capacity and a negative value removes from the current capacity, The number of instances by which to scale. AdjustmentType determines the interpretation of this number (e.g., as an absolute number or as a percentage of the existing Auto Scaling group size). A positive increment adds to the current capacity and a negative value removes from the current capacity"
        method_option :cooldown, :type => :numeric, :desc => "The amount of time, in seconds, after a scaling activity completes before any further trigger-related scaling activities can start"
        def create
          create_as_object
          @as.create options
        end

        desc "delete", "Deletes a policy created by put_scaling_policy"
        method_option :id, :aliases => "-n", :banner => "NAME", :required => true, :desc => "The name of the policy you want to delete"
        method_option :auto_scaling_group_name, :aliases => "-g", :required => true, :desc => "name of the auto scaling group"
        def delete
          create_as_object
          @as.delete options
        end

        private
        def create_as_object
          puts "AS Establishing Connetion..."
          $as_conn =  Awscli::Connection.new.request_as
          puts "AS Establishing Connetion... OK"
          @as = Awscli::As::Policies.new($as_conn)
        end

        AwsCli::CLI::As.register AwsCli::CLI::AS::Policies, :policies, 'policies [COMMAND]', 'Auto Scaling Policies Management'

      end
    end
  end
end