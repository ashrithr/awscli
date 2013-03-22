module Awscli
  module EC2

    class EC2

      # initialize ec2 class object
      # params:
      #   connection: Awscli::Connection.new.request_ec2
      #   extra options hash
      def initialize connection, options = {}
        @@conn = connection
      end

      # list instances from a specified region in a tabular format
      def list_instances
        @@conn.servers.table([:id, :dns_name, :flavor_id, :groups, :image_id, :key_name, :private_ip_address,
          :public_ip_address, :root_device_type, :security_group_ids, :state, :tags])
      end

      # list available instance types
      def list_flavors
        @@conn.flavors.table
      end

      # describe instance attributes - returns information about an attribute of an instance. You can get information
      #   only one attribute per call.
      #   Avaliable attributes to request: instanceType, kernel, ramdisk, userData, disableApiTermination, instanceInitiatedShutdownBehavior,
      #     rootDeviceName, blockDeviceMapping, sourceDestCheck, groupSet
      def describe_instance_attribute instance_id, request
        valid_requests = %w(architecture ami_launch_index availability_zone block_device_mapping network_interfaces client_token
          dns_name ebs_optimized groups flavor_id iam_instance_profile image_id instance_initiated_shutdown_behavior
          kernel_id key_name created_at monitoring placement_group platform private_dns_name private_ip_address
          public_ip_address ramdisk_id root_device_name root_device_type security_group_ids state state_reason subnet_id
          tenancy tags user_data vpc_id volumes username)
        #more options
        #:monitor=, :username=, :private_key=, :private_key_path=, :public_key=, :public_key_path=, :username, :private_key_path, :private_key, :public_key_path, :public_key, :scp, :scp_upload, :scp_download, :ssh, :ssh_port, :sshable?
        response = @@conn.servers.get(instance_id)
        abort "Invalid Attribute, available attributes to request: #{valid_requests}" unless valid_requests.include?(request)
        abort "InstanceId Not found :#{instance_id}, Available instnaces #{@@conn.servers.map { |x| x.id }}" unless response
        puts "#{request}: #{response.send(request)}"
      end

      # modifies an attribute of an instance
      def modify_instance_attribute instance_id, attributename, attributevalue
        attrs_lookup = {
          'isize' => 'InstanceType',
          'kernel' => 'Kernel',
          'ramdisk' => 'Ramdisk',
          'userdata' => 'UserData',
          'disable_api_term' => 'DisableApiTermination',
          'inst_shutdown_beh' => 'InstanceInitiatedShutdownBehavior',
          'source_dest_check' => 'SourceDestCheck',
          'group_id' => 'GroupId'
        }
        valid_attributes = %w(InstanceType Kernel Ramdisk UserData DisableApiTermination InstanceInitiatedShutdownBehavior SourceDestCheck GroupId)
        response = @@conn.servers.get(instance_id)
        abort "InstanceId Not found :#{instance_id}, Available instnaces #{@@conn.servers.map { |x| x.id }}" unless response
        abort "Instance should be in stopped state to modify its attributes" if response.state != 'stopped'
        puts "#{instance_id}, #{attributename}, #{attributevalue}"
        if attrs_lookup[attributename] == 'GroupId' #handle groupid which is array
          puts "#{instance_id}, #{attrs_lookup[attributename]} => #{attributevalue}"
          @@conn.modify_instance_attribute(instance_id, attrs_lookup[attributename] => attributevalue)
        else
          puts "#{instance_id}, #{attrs_lookup[attributename]}.Value => #{attributevalue}"
          @@conn.modify_instance_attribute(instance_id, "#{attrs_lookup[attributename]}.Value" => attributevalue)
        end
      end

      # reset instance attribute
      def reset_instance_attribute instance_id, attribute
      end

      #create a single instance with optons passed
      def create_instance options
        #validate required options
        puts "Validating Options ..."
        abort "Invalid Key: #{options[:key_name]}" unless @@conn.key_pairs.get(options[:key_name])
        options[:groups].each do |sg|
          abort "Invalid Group: #{sg}" unless @@conn.security_groups.get(sg)
        end
        abort "Invalid AMI: #{options[:image_id]}" unless @@conn.images.get(options[:image_id])
        abort "Invalid Instance Flavor: #{options[:flavor_id]}" unless @@conn.flavors.get(options[:flavor_id])
        #validate optional options
        if options[:availability_zone]
          available_zones = @@conn.describe_availability_zones.body['availabilityZoneInfo'].map { |az| az['zoneName'] }
          abort "Invalid AvailabilityZone: #{options[:availability_zone]}" unless available_zones.include?(options[:availability_zone])
        end
        opts = Marshal.load(Marshal.dump(options))
        wait_for_server = options[:wait_for] && opts.reject! { |k| k == 'wait_for' }
        puts "Validating Options ... OK"
        puts "Creating Server"
        server = @@conn.servers.create(opts)
        #wait for server to get created and return public_dns
        if wait_for_server
          print "Waiting for server to get created "
          server.wait_for { print "."; ready? }
          puts
          puts "Server dns_name: #{server.dns_name}"
        end
      end

        # Launch specified instances
        #
        # ==== Parameters
        # * image_id<~String> - Id of machine image to load on instances
        # * min_count<~Integer> - Minimum number of instances to launch. If this
        #   exceeds the count of available instances, no instances will be
        #   launched.  Must be between 1 and maximum allowed for your account
        #   (by default the maximum for an account is 20)
        # * max_count<~Integer> - Maximum number of instances to launch. If this
        #   exceeds the number of available instances, the largest possible
        #   number of instances above min_count will be launched instead. Must
        #   be between 1 and maximum allowed for you account
        #   (by default the maximum for an account is 20)
        # * options<~Hash>:
        #   * 'Placement.AvailabilityZone'<~String> - Placement constraint for instances
        #   * 'Placement.GroupName'<~String> - Name of existing placement group to launch instance into
        #   * 'Placement.Tenancy'<~String> - Tenancy option in ['dedicated', 'default'], defaults to 'default'
        #   * 'BlockDeviceMapping'<~Array>: array of hashes
        #     * 'DeviceName'<~String> - where the volume will be exposed to instance
        #     * 'VirtualName'<~String> - volume virtual device name
        #     * 'Ebs.SnapshotId'<~String> - id of snapshot to boot volume from
        #     * 'Ebs.VolumeSize'<~String> - size of volume in GiBs required unless snapshot is specified
        #     * 'Ebs.DeleteOnTermination'<~String> - specifies whether or not to delete the volume on instance termination
        #   * 'ClientToken'<~String> - unique case-sensitive token for ensuring idempotency
        #   * 'DisableApiTermination'<~Boolean> - specifies whether or not to allow termination of the instance from the api
        #   * 'SecurityGroup'<~Array> or <~String> - Name of security group(s) for instances (not supported for VPC)
        #   * 'SecurityGroupId'<~Array> or <~String> - id's of security group(s) for instances, use this or SecurityGroup
        #   * 'InstanceInitiatedShutdownBehaviour'<~String> - specifies whether volumes are stopped or terminated when instance is shutdown, in [stop, terminate]
        #   * 'InstanceType'<~String> - Type of instance to boot. Valid options
        #     in ['t1.micro', 'm1.small', 'm1.large', 'm1.xlarge', 'c1.medium', 'c1.xlarge', 'm2.xlarge', m2.2xlarge', 'm2.4xlarge', 'cc1.4xlarge', 'cc2.8xlarge', 'cg1.4xlarge']
        #     default is 'm1.small'
        #   * 'KernelId'<~String> - Id of kernel with which to launch
        #   * 'KeyName'<~String> - Name of a keypair to add to booting instances
        #   * 'Monitoring.Enabled'<~Boolean> - Enables monitoring, defaults to
        #     disabled
        #   * 'PrivateIpAddress<~String> - VPC option to specify ip address within subnet
        #   * 'RamdiskId'<~String> - Id of ramdisk with which to launch
        #   * 'SubnetId'<~String> - VPC option to specify subnet to launch instance into
        #   * 'UserData'<~String> -  Additional data to provide to booting instances
        #   * 'EbsOptimized'<~Boolean> - Whether the instance is optimized for EBS I/O
      # create a new instnace
      def run_instances
      end

      # describe instnace status
      def describe_instance_status
      end

      # import instance as vm
      def import_instance
      end

      #@@conn.server.get(instanceid).(:reboot, :save, :setup, :start, :stop)
      # reboot an instance
      def reboot_instance instance_id
      end

      # start a stopped instance
      def stop_instance instance_id
      end

      # stop a running isntance
      def stop_instance instance_id
      end

      # terminates an instance
      def terminate_instance instance_id
      end

    end # => EC2

    class KeyPairs
      def initialize connection, options = {}
        @@conn = connection
      end

      def list_keypairs
        @@conn.key_pairs.table
      end
    end # => KP

    class SecGroups
      def initialize connection, options = {}
        @@conn = connection
      end

      def list_secgroups
        @@conn.security_groups.table([:name, :group_id, :description])
      end
    end # => SG

    class Ami
      def initialize connection, options = {}
        @@conn = connection
      end

      def list_images_amazon
        @@conn.images.all('owner-id' => '470254534024').table([:architecture, :id, :is_public, :platform,
                                                                  :root_device_type, :state])
      end
    end # => AMI

    class Ebs
      def initialize connection, options = {}
        @@conn = connection
      end
    end # => EBS

    class Eip
      def initialize connection, options = {}
        @@conn = connection
      end
    end # => EIP

  end
end