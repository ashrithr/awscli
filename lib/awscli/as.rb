module Awscli
  module As

    class Activities
      def initialize connection, options = {}
        @@conn = connection
      end

      def list options
        if options[:group_name]
          puts @@conn.describe_scaling_activities('AutoScalingGroupName' => options[:group_name]).body['DescribeScalingActivitiesResult']['Activities'].to_yaml
        else
          puts @@conn.describe_scaling_activities.body['DescribeScalingActivitiesResult']['Activities'].to_yaml
        end
      end
    end

    class Configurations
      def initialize connection, options = {}
        @@conn = connection
      end

      def list options
        if options[:table]
          @@conn.configurations.table([:id, :instance_type, :key_name, :security_groups])
        else
          puts @@conn.describe_launch_configurations.body['DescribeLaunchConfigurationsResult']['LaunchConfigurations'].to_yaml
        end
      end

      def create options
        #validate block device mapping and parse it to a hash understandable by fog
        opts = Marshal.load(Marshal.dump(options))
        block_device_mapping = Array.new
        if options[:block_device_mappings]
          options[:block_device_mappings].each do |group|
            mapping = Hash.new
            #parse options
            abort "Invalid block device mapping format, expecting 'devicename=blockdevice' format" unless group =~ /\S=\S/
            device_name, block_device = group.split("=")
            abort "Invalid device name, expectiing '/dev/sd[a-z]'" unless device_name =~ /^\/dev\/sd[a-z]$/
            abort "Invalud block device format, expecting 'ephemeral[0..3]|none|[snapshot-id]:[volume-size]:[true|false]:[standard|io1[:iops]]'" unless block_device =~ /^(snap-.*|ephemeral\w{1,3}|none|:.*)$/
            mapping['DeviceName'] = device_name
            case block_device
            when 'none'
              mapping['Ebs.NoDevice'] = 'true'
            when /ephemeral/
              mapping['VirtualName'] = block_device
            when /snap-.*|:.*/
              snapshot_id, volume_size, delete_on_termination, volume_type, iops = block_device.split(":")
              mapping['Ebs.SnapshotId'] = snapshot_id if !snapshot_id.nil? && !snapshot_id.empty?
              mapping['Ebs.VolumeSize'] = volume_size if !volume_size.nil? && !volume_size.empty?
              mapping['Ebs.DeleteOnTermination'] = delete_on_termination if !delete_on_termination.nil? && !delete_on_termination.empty?
            else
              abort "Cannot validate block_device"
            end
            block_device_mapping << mapping
          end
        end
        if block_devices = opts.delete(:block_device_mappings)
          opts.merge!('BlockDeviceMappings' => block_device_mapping)
        end
        if key_name = opts.delete(:key_name)
          opts.merge!('KeyName' => key_name)
        end
        if sec_grps = opts.delete(:security_groups)
          opts.merge!('SecurityGroups' => sec_grps)
        end
        if spot_price = opts.delete(:spot_price)
          opts.merge!('SpotPrice' => spot_price)
        end
        if user_data = opts.delete(:user_data)
          opts.merge!('UserData' => user_data)
        end
        if instance_monitoring = opts.delete(:instance_monitoring)
          opts.merge!('InstanceMonitoring.Enabled' => instance_monitoring)
        end
        opts.reject! { |k| k == 'image_id' }
        opts.reject! { |k| k == 'instance_type' }
        opts.reject! { |k| k == 'id' }

        begin
          cfgs = @@conn.create_launch_configuration(options[:image_id], options[:instance_type], options[:id], opts)
          puts "Created Launch Configuration, #{options[:id]}"
        rescue Fog::AWS::AutoScaling::IdentifierTaken
          puts "A launch configuration already exists with the name #{options[:id]}"
        end
      end

      def delete cfg_name
        cfg = @@conn.configurations.get(cfg_name)
        abort "Cannot find launch configuration with name: #{cfg_name}" unless cfg
        cfg.destroy
        puts "Deleted Launch Configuration with name: #{cfg_name}"
      end
    end

    class Groups
      def initialize connection, options = {}
        @@conn = connection
      end

      def list options
        if options[:table]
          @@conn.groups.table([:id, :launch_configuration_name, :desired_capacity, :min_size, :max_size, :vpc_zone_identifier, :termination_policies])
        else
          #yaml dump
          puts @@conn.describe_auto_scaling_groups.body['DescribeAutoScalingGroupsResult']['AutoScalingGroups'].to_yaml
        end
      end

      def create options
        # => validate & parse options
        opts = Marshal.load(Marshal.dump(options))
        #launch conf name
        abort "Launch configuration name not found: #{options[:launch_configuration_name]}" unless @@conn.configurations.get(options[:launch_configuration_name])
        #remove required options from options hash
        opts.reject! { |k| k == 'id' }
        opts.reject! { |k| k == 'availability_zones' }
        opts.reject! { |k| k == 'launch_configuration_name' }
        opts.reject! { |k| k == 'max_size' }
        opts.reject! { |k| k == 'min_size' }
        if desired_capacity = opts.delete(:desired_capacity)
          opts.merge!('DesiredCapacity' => desired_capacity)
        end
        if default_cooldown = opts.delete(:default_cooldown)
          opts.merge!('DefaultCooldown' => default_cooldown)
        end
        if health_check_grace_period = opts.delete(:health_check_grace_period)
          opts.merge!('HealthCheckGracePeriod' => health_check_grace_period)
        end
        if health_check_type = opts.delete(:health_check_type)
          opts.merge!('HealthCheckType' => health_check_type)
        end
        if load_balancer_names = opts.delete(:load_balancer_names)
          opts.merge!('LoadBalancerNames' => load_balancer_names)
        end
        if placement_group = opts.delete(:placement_group)
          opts.merge!('PlacementGroup' => placement_group)
        end
        if tags = opts.delete(:tags)
          parsed_tags = Array.new
          tags.each do |t|
            abort "Invliad tags format, expecting 'key=value' format" unless t =~ /\S=\S/
          end
          tags.each do |tag|
            parsed_tag = Hash.new
            key, value = tag.split("=")
            parsed_tag['Key'] = key
            parsed_tag['Value'] = value
            parsed_tags << parsed_tag
          end
          opts.merge!('Tags' => parsed_tags)
        end
        if termination_policies = opts.delete(:termination_policies)
          opts.merge!('TerminationPolicies' => termination_policies)
        end
        if vpc_zone_identifiers = opts.delete(:vpc_zone_identifiers)
          opts.merge!('VPCZoneIdentifier' => vpc_zone_identifiers.join(','))
        end
        begin
          @@conn.create_auto_scaling_group(
            options[:id],
            options[:availability_zones],
            options[:launch_configuration_name],
            options[:max_size],
            options[:min_size],
            opts
          )
          puts "Created Auto Scaling Group with name: #{options[:id]}"
        rescue Fog::AWS::AutoScaling::IdentifierTaken
          puts "A auto-scaling-group already exists with the name #{options[:id]}"
        rescue Fog::AWS::AutoScaling::ValidationError
          puts "Validation Error: #{$!}"
        end
      end

      def set_desired_capacity options
        # => Sets the desired capacity of the auto sacling group
        asg = @@conn.groups.get(options[:id])
        abort "Cannot find Auto Scaling Group with name: #{options[:id]}" unless asg
        min_size = asg.min_size
        max_size = asg.max_size
        abort "Desired capacity should fall in between auto scaling groups min-size: #{min_size} and max-size: #{max_size}" unless options[:desired_capacity].between?(min_size, max_size)
        abort "Desired capacity is already #{asg.desired_capacity}" if options[:desired_capacity] == asg.desired_capacity
        @@conn.set_desired_capacity(options[:id], options[:desired_capacity])
        puts "Scaled Auto Scaling Group: #{options[:id]} to a desired_capacity of #{options[:desired_capacity]}"
      end

      # def update
      #   asg = @@conn.groups.get(options[:id])
      #   abort "Cannot find Auto Scaling Group with name: #{options[:id]}" unless asg
      #   opts = Marshal.load(Marshal.dump(options))
      #   opts.reject! { |k| k == 'id' }
      #   asg.update(opts)
      # end

      def suspend_processes options
        if options[:scaling_processes]
          @@conn.suspend_processes(
            options[:id],
            'ScalingProcesses' => options[:scaling_processes])
          puts "Suspending processes #{options[:scaling_processes]} for group: #{options[:id]}"
        else
          @@conn.suspend_processes(options[:id])
          puts "Suspending processes for group: #{options[:id]}"
        end
      end

      def resume_processes options
        if options[:scaling_processes]
          @@conn.resume_processes(
            options[:id],
            'ScalingProcesses' => options[:scaling_processes]
            )
          puts "Resuming processes #{options[:scaling_processes]} for group: #{options[:id]}"
        else
          @@conn.resume_processes(options[:id])
          puts "Resuming processes for group: #{options[:id]}"
        end
      end

      def delete options
        begin
          if options[:force]
            @@conn.delete_auto_scaling_group(
              options[:id],
              'ForceDelete' => options[:force]
            )
          else
            @@conn.delete_auto_scaling_group(options[:id])
          end
        rescue Fog::AWS::AutoScaling::ResourceInUse
          puts "You cannot delete an AutoScalingGroup while there are instances or pending Spot instance request(s) still in the group"
          puts "Use -f option to force delete instances attached to the sacling group"
          exit 1
        end
        puts "Deleted Auto scaling group #{options[:id]}"
      end
    end

    class Instances
      def initialize connection, options = {}
        @@conn = connection
      end

      def list
        @@conn.instances.table
      end

      def terminate instance_id, decrement_capacity
        instance = @@conn.instances.get(instance_id)
        abort "Cannot find instace with id: #{instance_id}" unless instance
        begin
          @@conn.terminate_instance_in_auto_scaling_group(instance_id, decrement_capacity)
          puts "Terminated Instance with id: #{instance_id}"
          puts "Decrement Capacity of the scaling group: #{instance.auto_scaling_group_name} by 1" if decrement_capacity
        rescue Fog::AWS::AutoScaling::ValidationError
          puts "Validation Error: #{$!}"
        end
      end
    end

    class Policies
      def initialize connection, options = {}
        @@conn = connection
      end

      def list
        @@conn.policies.table
      end

      def create options
        @@conn.policies.create(options)
        puts "Created auto sacling policy: #{options[:id]}, for auto scaling group: #{options[:auto_scaling_group_name]}"
      end

      def destroy options
        @@conn.policies.destroy(options)
        puts "Deleted auto scaling policy: #{options[:id]}"
      end
    end

  end
end