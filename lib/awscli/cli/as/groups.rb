module AwsCli
  module CLI
    module AS
      require 'awscli/cli/as'
      class Groups < Thor

        desc "list [OPTIONS]", "list auto scaling groups"
        method_option :table, :aliases => "-t", :type => :boolean, :desc => "simple format listing in a table"
        def list
          create_as_object
          @as.list options
        end

        desc "create", "create a new auto scaling group"
        method_option :id, :aliases => "-n", :banner => "NAME", :required => true, :desc => "name of the auto scaling group to create"
        method_option :availability_zones, :aliases => "-z", :type => :array, :required => true, :desc => "A list of availability zones for the Auto Scaling group"
        method_option :launch_configuration_name, :aliases => "-c", :required => true, :banner => "CFG_NAME", :desc => "The name of the launch configuration to use with the Auto Scaling group"
        method_option :min_size, :aliases => "-l", :type => :numeric, :required => :true, :desc => "The minimum size of the Auto Scaling group"
        method_option :max_size, :aliases => "-h", :type => :numeric, :required => :true, :desc => "The maximum size of the Auto Scaling group"
        method_option :desired_capacity, :aliases => "-r", :type => :numeric, :desc => "The number of Amazon EC2 instances that should be running in the group"
        method_option :default_cooldown, :aliases => "-t", :type => :numeric, :desc => "The amount of time, in seconds, after a scaling activity completes before any further trigger-related scaling activities can start"
        method_option :health_check_grace_period, :type => :numeric, :desc => "Length of time in seconds after a new Amazon EC2 instance comes into service that Auto Scaling starts checking its health"
        method_option :health_check_type, :desc => "The service you want the health status from, Amazon EC2 or Elastic Load Balancer. Valid values are 'EC2' or 'ELB'"
        method_option :load_balancer_names, :type => :array, :desc => "A list of LoadBalancers to use"
        method_option :placement_group, :desc => "Physical location of your cluster placement group created in Amazon EC2"
        method_option :tags, :type => :array, :desc => "list of key=value pairs used for tags"
        method_option :termination_policies, :type => :array, :desc => "A standalone termination policy or a list of termination policies used to select the instance to terminate. The policies are executed in the order that they are listed"
        method_option :vpc_zone_identifiers, :type => :array, :desc => "A list of subnet identifiers of Amazon Virtual Private Clouds (Amazon VPCs)"
        def create
          create_as_object
          @as.create options
        end

        desc "delete", "delete an existing auto scaling group"
        method_option :id, :aliases => "-n", :banner => "NAME", :required => true, :desc => "name of the auto sacling group to delete"
        method_option :force, :aliases => "-f", :type => :boolean, :desc => "force deletes instances of the specified auto scaling group"
        def delete
          create_as_object
          @as.delete options
        end

        desc "scale", "change the desired capacity of a auto sacling group"
        method_option :id, :aliases => "-n", :banner => "NAME", :required => true, :desc => "name of the auto sacling group to scale"
        method_option :desired_capacity, :aliases => "-c", :type => :numeric, :banner => "SIZE", :required => true, :desc => "Desired capacity of a auto scaling group"
        def scale
          create_as_object
          @as.set_desired_capacity options
        end

        # desc "update", "update auto scaling group attributes"
        # method_option :id, :aliases => "-n", :banner => "NAME", :required => true, :desc => "name of the auto sacling group to scale"
        # method_option :availability_zones, :aliases => "-z", :type => :array, :desc => "A list of availability zones for the Auto Scaling group"
        # method_option :desired_capacity, :aliases => "-r", :type => :numeric, :desc => "The number of Amazon EC2 instances that should be running in the group"
        # method_option :default_cooldown, :aliases => "-t", :type => :numeric, :desc => "The amount of time, in seconds, after a scaling activity completes before any further trigger-related scaling activities can start"
        # method_option :health_check_grace_period, :type => :numeric, :desc => "Length of time in seconds after a new Amazon EC2 instance comes into service that Auto Scaling starts checking its health"
        # method_option :health_check_type, :desc => "The service you want the health status from, Amazon EC2 or Elastic Load Balancer. Valid values are 'EC2' or 'ELB'"
        # method_option :launch_configuration_name, :aliases => "-c", :banner => "CFG_NAME", :desc => "The name of the launch configuration to use with the Auto Scaling group"
        # method_option :min_size, :aliases => "-l", :type => :numeric, :desc => "The minimum size of the Auto Scaling group"
        # method_option :max_size, :aliases => "-h", :type => :numeric, :desc => "The maximum size of the Auto Scaling group"
        # method_option :termination_policies, :type => :array, :desc => "A standalone termination policy or a list of termination policies used to select the instance to terminate. The policies are executed in the order that they are listed"
        # method_option :vpc_zone_identifiers, :type => :array, :desc => "A list of subnet identifiers of Amazon Virtual Private Clouds (Amazon VPCs)"
        # def update
        #   create_as_object
        #   @as.update options
        # end

        desc "suspend", "Suspends Auto Scaling processes for an Auto Scaling group. To suspend specific process types, specify them by name with the ScalingProcesses parameter. To suspend all process types, omit the ScalingProcesses"
        method_option :id, :aliases => "-n", :banner => "NAME", :required => true, :desc => "name of the auto sacling group to suspend processes"
        method_option :scaling_processes, :aliases => "-p", :type => :array, :desc => "The processes that you want to suspend. To suspend all process types, omit this parameter"
        def suspend
          create_as_object
          @as.suspend_processes options
        end

        desc "resume", "Resumes Auto Scaling processes for an Auto Scaling group"
        method_option :id, :aliases => "-n", :banner => "NAME", :required => true, :desc => "name of the auto sacling group to resume processes"
        method_option :scaling_processes, :aliases => "-p", :type => :array, :desc => "The processes that you want to resume. To resume all process types, omit this parameter"
        def resume
          create_as_object
          @as.resume_processes options
        end


        private
        def create_as_object
          puts "AS Establishing Connetion..."
          $as_conn =  Awscli::Connection.new.request_as
          puts "AS Establishing Connetion... OK"
          @as = Awscli::As::Groups.new($as_conn)
        end

        AwsCli::CLI::As.register AwsCli::CLI::AS::Groups, :groups, 'groups [COMMAND]', 'Auto Scaling Groups Management'

      end
    end
  end
end