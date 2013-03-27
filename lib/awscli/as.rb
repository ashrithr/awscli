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
          puts "Created Launch Configuration, #{cfgs.body['ResponseMetadata']['ac678d01-967a-11e2-a40a-d316dcab3807']}"
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

  end
end