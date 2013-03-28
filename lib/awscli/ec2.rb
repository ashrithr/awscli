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

      #create a single instance with options passed
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
        block_device_mapping = Array.new
        #validate block device mapping and parse it to a hash understandable by fog
        if options[:block_device_mapping]
          options[:block_device_mapping].each do |group|
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
        if block_devices = opts.delete(:block_device_mapping)
          opts.merge!(:block_device_mapping => block_device_mapping)
        end
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

      # create a new instnace(s)
      def run_instances options
      end

      # describe instnace status
      def describe_instance_status instnace_id
        response = @@conn.servers.get(instance_id)
        abort "InstanceId Not found :#{instance_id}" unless response
        puts "Instance #{instance_id} State: #{response.state}"
      end

      # import instance as vm
      def import_instance
      end

      #@@conn.server.get(instanceid).(:reboot, :save, :setup, :start, :stop)
      # reboot an instance
      def reboot_instance instance_id
        response = @@conn.servers.get(instance_id)
        abort "InstanceId Not found :#{instance_id}" unless response
        response.reboot
        puts "Rebooting Instance: #{instance_id}"
      end

      # start a stopped instance
      def stop_instance instance_id
        response = @@conn.servers.get(instance_id)
        abort "InstanceId Not found :#{instance_id}" unless response
        abort "Instance should be in running to stop it" if response.state != 'running'
        response.stop
        puts "Stopped Instance: #{instance_id}"
      end

      # stop a running isntance
      def start_instance instance_id
        response = @@conn.servers.get(instance_id)
        abort "InstanceId Not found :#{instance_id}" unless response
        abort "Instance should be stopped to start it" if response.state != 'stopped'
        response.start
        puts "Starting Instance: #{instance_id}"
      end

      # terminates an instance
      def terminate_instance instance_id
        response = @@conn.servers.get(instance_id)
        abort "InstanceId Not found :#{instance_id}" unless response
        unless response.state == 'terminated'
          response.destroy
          puts "Terminated Instance: #{instance_id}"
        else
          puts "Instance is already in terminated state"
        end
      end

      def get_console_output instance_id
        response = @@conn.get_console_output(instance_id)
        puts response
      end

    end # => EC2

    class KeyPairs
      def initialize connection, options = {}
        @@conn = connection
      end

      def list_keypairs
        @@conn.key_pairs.table
      end

      def create_keypair options
        #validate keypair
        Fog.credential = 'awscli'
        abort "KeyPair '#{options[:name]}' already exists" if @@conn.key_pairs.get(options[:name])
        kp = @@conn.key_pairs.create(options)
        puts "Created keypair: #{options[:name]}"
        p kp.write  #save the key to disk
      end

      def delete_keypair keypair
        abort "KeyPair '#{keypair}' does not exist" unless @@conn.key_pairs.get(keypair)
        @@conn.key_pairs.get(keypair).destroy
        puts "Deleted Keypair: #{keypair}"
      end

      def fingerprint keypair
        response = @@conn.key_pairs.get(keypair)
        abort "Cannot find key pair: #{keypair}" unless response
        puts "Fingerprint for the key (#{keypair}): #{response.fingerprint}"
      end

      def import_keypair options
        #validate if the file exists
        private_key_path = if options[:private_key_path]
                            File.expand_path(options[:private_key_path])
                           else
                            File.expand_path("~/.ssh/#{options[:name]}")
                           end
        public_key_path  = if options[:public_key_path]
                            File.expand_path(options[:public_key_path])
                           else
                            File.expand_path("~/.ssh/#{options[:name]}.pub")
                           end
        abort "Cannot find private_key_path: #{private_key_path}" unless File.exist?(private_key_path)
        abort "Cannot find public_key_path: #{public_key_path}" unless File.exist?(public_key_path)
        #validate if the key pair name exists
        Fog.credentials = Fog.credentials.merge({ :private_key_path => private_key_path, :public_key_path => public_key_path })
        @@conn.import_key_pair(options[:name], IO.read(public_key_path)) if @@conn.key_pairs.get(options[:name]).nil?
        puts "Imported KeyPair with name: #{options[:name]} sucessfully, using public_key: #{public_key_path} and private_key: #{private_key_path}"
      end
    end # => KP

    class SecGroups

      #Limitations: Ec2-Classic: user can have upto 500 groups
                  # Ec2-VPC: user can have 50 group per VPC

      def initialize connection, options = {}
        @@conn = connection
      end

      def list_secgroups options
        if options[:show_ip_permissions]
          # @@conn.security_groups.table([:name, :group_id, :ip_permissions])
          @@conn.security_groups.each do |sg|
            id = sg.group_id
            ip_permissions = sg.ip_permissions.to_yaml
            Formatador.display_line("[green]#{id}[/]")
            puts "#{ip_permissions}"
            puts "================="
          end
        else
          @@conn.security_groups.table([:name, :group_id, :description])
        end
      end

      def authorize_securitygroup options
        # => Ingress regular traffic -> this action applies to both EC2 and VPC Security Groups
            # Each rule consists of the protocol, plus cidr range or a source group,
              #for TCP/UDP protocols you must also specify the dest port or port range
              #for ICMP, you must specify the icmp type and code (-1 means all types/codes)
        abort "Expecting Security group id(s) of the form: 'sg-xxxxxx'" unless options[:group_id] =~ /sg-\S{8}/
        abort "Invalid CIDR format" unless options[:cidr] =~ /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/(\d|[1-2]\d|3[0-2]))$/
        sg = @@conn.security_groups.get_by_id(options[:group_id])
        abort "Cannot find Security Group with Id: #{sg}" unless sg
        begin
          @@conn.authorize_security_group_ingress(
            "GroupId" => options[:group_id],
            "IpProtocol" => options[:protocol_type],
            "FromPort" => options[:start_port],
            "ToPort" => options[:end_port],
            "CidrIp" => options[:cidr]
            )
          puts "Authorized rule"
        rescue Fog::Compute::AWS::Error #=> e
          abort "Error: #{$!}"
          #puts $@ #backtrace
        end
      end

      def revoke_securitygroup options
        abort "Expecting Security group id(s) of the form: 'sg-xxxxxx'" unless options[:group_id] =~ /sg-\S{8}/
        sg = @@conn.security_groups.get_by_id(options[:group_id])
        abort "Cannot find Security Group with Id: #{sg}" unless sg
        begin
          response = @@conn.revoke_security_group_ingress(
            "GroupId" => options[:group_id],
            "IpProtocol" => options[:protocol_type],
            "FromPort" => options[:start_port],
            "ToPort" => options[:end_port],
            "CidrIp" => options[:cidr]
            )
          puts "Revoked rule: #{response.body['return']}"
        rescue Fog::Compute::AWS::Error #=> e
          abort "Error: #{$!}"
        end
      end

      def create_securitygroup options
        abort "Error: Security Group => #{options[:name]} already exists" if @@conn.security_groups.get(options[:name])
        @@conn.security_groups.create(options)
        puts "Created Security Group: #{options[:name]}"
      end

      def delete_securitygroup options
        sg = @@conn.security_groups.get_by_id(options[:group_id])
        abort "Error: Cannot find Security Group with Id: #{sg}" unless sg
        begin
          sg.destroy
          puts "Deleted Security Group with id: #{options[:group_id]}"
        rescue Fog::Compute::AWS::Error #=> e
          abort "Error: #{$!}"
        end
      end

    end # => SG

    class Eip
      def initialize connection, options = {}
        @@conn = connection
      end

      def list
        @@conn.addresses.table
      end

      def create
        eip = @@conn.addresses.create
        puts "Created EIP: #{eip.public_ip}"
      end

      def delete options
        abort "Invalid IP Format" unless options[:eip] =~ /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/
        eip = @@conn.addresses.get(options[:eip])
        abort "Cannot find IP: #{options[:eip]}" unless eip
        eip.destroy
        puts "Deleted EIP: #{eip.public_ip}"
      end

      def associate options
        abort "Invalid IP Format" unless options[:eip] =~ /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/
        eip = @@conn.addresses.get(options[:eip])
        abort "Cannot find eip: #{options[:eip]}" unless eip
        server = @@conn.servers.get(options[:instance_id])
        abort "Cannot find server with id: #{options[:instance_id]}" unless server
        begin
          eip.server = server
          puts "Associated EIP: #{options[:eip]} with Instance: #{options[:instance_id]}"
        rescue Fog::Compute::AWS::Error
          abort "Error: #{$!}"
        end
      end

      def disassociate options
        abort "Invalid IP Format" unless options[:eip] =~ /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/
        abort "Cannot find EIP: #{options[:eip]}" unless @@conn.addresses.get(options[:eip])
        @@conn.disassociate_address(options[:eip])
        puts "Disassociated EIP: #{options[:eip]}"
      end
    end # => Eip

    class Ami
      def initialize connection, options = {}
        @@conn = connection
      end

      def list filter
        puts filter
        if filter.nil?
          @@conn.images.all.table([:architecture, :id, :is_public, :platform, :root_device_type, :state])
        else
          @@conn.images.all(filter).table([:architecture, :id, :is_public, :platform, :root_device_type, :state])
        end
      end

      def show_filters
        filters =
          [
            {:filter_name => "architecture", :desc => "Image Architecture"},
            {:filter_name => "block-device-mapping.delete-on-termination", :desc => "Whether the Amazon EBS volume is deleted on instance termination"},
            {:filter_name => "block-device-mapping.device-name", :desc => "Device name (e.g., /dev/sdh) for an Amazon EBS volume mapped to the image"},
            {:filter_name => "block-device-mapping.snapshot-id", :desc => "Snapshot ID for an Amazon EBS volume mapped to the image"},
            {:filter_name => "block-device-mapping.volume-size", :desc => "Volume size for an Amazon EBS volume mapped to the image"},
            {:filter_name => "description", :desc => "Description of the AMI (provided during image creation)"},
            {:filter_name => "image-id", :desc => "ID of the image" },
            {:filter_name => "imgae-type", :desc => "Type of image" },
            {:filter_name => "is-public", :desc => "Whether the image is public" },
            {:filter_name => "kernel-id", :desc => "Kernel ID" },
            {:filter_name => "manifest-location", :desc => "Location of the image manifest" },
            {:filter_name => "name", :desc => "Name of the AMI (provided during image creation)" },
            {:filter_name => "owner-alias", :desc => "AWS account alias (e.g., amazon or self) or AWS account ID that owns the AMI" },
            {:filter_name => "owner-id", :desc => "AWS account ID of the image owner" },
            {:filter_name => "platform", :desc => "Use windows if you have Windows based AMIs; otherwise leave blank" },
            {:filter_name => "product-code", :desc => "Product code associated with the AMI" },
            {:filter_name => "ramdisk-id", :desc => "RAM disk ID" },
            {:filter_name => "root-device-name", :desc => "Root device name of the AMI (e.g., /dev/sda1)" },
            {:filter_name => "root-device-type", :desc => "Root device type the AMI uses" },
            {:filter_name => "state", :desc => "State of the image" },
            {:filter_name => "state-reason-code", :desc => "Reason code for the state change" },
            {:filter_name => "state-reason-message", :desc => "Message for the state change" },
            {:filter_name => "tag-key", :desc => "Key of a tag assigned to the resource. This filter is independent of the tag-value filter" },
            {:filter_name => "tag-value", :desc => "Value of a tag assigned to the resource. This filter is independent of the tag-key filter." },
            {:filter_name => "virtualization-type", :desc => "Virtualization type of the image" },
            {:filter_name => "hypervisor", :desc => "Hypervisor type of the image" }
          ]
        Formatador.display_table(filters, [:filter_name, :desc])
      end

      def list_amazon
        @@conn.images.all('owner-alias' => 'amazon').table([:architecture, :id, :is_public, :platform, :root_device_type, :state])
      end

      def create_image_from_instance options
        abort "Invalid Instace: #{options[:instance_id]}" unless @@conn.servers.get(options[:instance_id])
        @@conn.create_image(
            options[:instance_id],
            options[:name],
            options[:desc],
            options[:no_reboot]
          )
        puts "Created image from instance: #{options[:instance_id]}"
      end

    end # => AMI

    class Ebs
      def initialize connection, options = {}
        @@conn = connection
      end

      def list options
        unless options[:snapshots]
          @@conn.volumes.table([:availability_zone, :delete_on_termination, :device, :id, :server_id, :size, :snapshot_id, :state, :tags, :type])
        else
          @@conn.snapshots.table([:id, :owner_id, :volume_id, :state, :progress, :tags, :description])
        end
      end

      def create options
        @@conn.volumes.create(options)
      end

      def attach_volume options
        #The volume and instance must be in the same Availability Zone.
        volume = @@conn.volumes.get(options[:volume_id])
        volume.merge_attributes(:device => options[:device])
        server = @@conn.servers.get(options[:instance_id])
        abort "Cannot find volume: #{options[:volume_id]}" unless volume
        abort "Cannot find instance: #{options[:instance_id]}" unless server
        volume.server = server
        puts "Attached volume: #{options[:volume_id]} to instance: #{options[:instance_id]}"
      end

      def detach_volume options
        #Check if the volume is mounted and show warning regarding data loss
        volume = @@conn.volumes.get(options[:volume_id])
        abort "Cannot find volume: #{options[:volume_id]}" unless volume
        if options[:force]
          volume.force_detach
        else
          @@conn.detach_volume(options[:volume_id])
        end
        puts "Detached volume: #{options[:volume_id]}"
      end

      def delete_volume options
        vol = @@conn.volumes.get(options[:volume_id])
        abort "Cannot find volume #{options[:volume_id]}" unless vol
        vol.destroy
        puts "Deleted volume: #{options[:volume_id]}"
      end

      def create_snapshot options
        abort "Cannot find volume: #{options[:volume_id]}" unless @@conn.volumes.get(options[:volume_id])
        @@conn.snapshots.create(options)
        puts "Created snapshot"
      end

      def copy_snapshot options
        abort "Cannot find snapshot: #{options[:snapshot_id]}" unless @@conn.snapshots.get(options[:snapshot_id])
        @@conn.copy_snapshot(options[:snapshot_id], options[:source_region])
        puts "Copied snapshot"
      end

      def delete_snapshot options
        snap = @@conn.snapshots.get(options[:snapshot_id])
        abort "Cannot find snapshot: #{options[:snapshot_id]}" unless snap
        snap.destroy
        puts "Destroyed snapshot"
      end
    end # => EBS

    class Monitor
      def initialize connection, options = {}
        @@conn = connection
      end

      def monitor options
        options[:instance_ids].each do |instance|
          abort "Invalid InstanceId: #{instance}" unless @@conn.servers.get(instance)
        end
        @@conn.monitor_instances(options[:instance_ids])
        puts "Enabled monitoring for instnaces: #{options[:instance_ids].join(",")}"
      end

      def unmonitor options
        options[:instance_ids].each do |instance|
          abort "Invalid InstanceId: #{instance}" unless @@conn.servers.get(instance)
        end
        @@conn.unmonitor_instances(options[:instance_ids])
        puts "Disabled monitoring for instnaces: #{options[:instance_ids].join(",")}"
      end
    end # => Monitor

    class Tags
      def initialize connection, options = {}
        @@conn = connection
      end

      def list
        @@conn.tags.table
      end

      def create options
        @@conn.tags.create(options)
        puts "Created Tag"
      end

      def delete options
        @@conn.tags.destroy(options)
        puts "Deleted Tag"
      end
    end # => Tags

    class Placement
      def initialize connection, options = {}
        @@conn = connection
      end

      def list
        @@conn.describe_placement_groups
      end

      def create options
        @@conn.create_placement_group(options[:name], options[:strategy])
        puts "Created a new placement group: #{options[:name]}"
      end

      def delete options
        @@conn.delete_placement_group(options[:name])
        puts "Deleted placement group: #{options[:name]}"
      end
    end # => Placement

    class ReservedInstances
      def initialize connection, options = {}
        @@conn = connection
      end

      def list filters
        puts filters
        if filters.nil?
          @@conn.describe_reserved_instances.body['reservedInstancesSet']
        else
          @@conn.describe_reserved_instances(filters).body['reservedInstancesSet']
        end
      end

      def list_offerings filters
        puts filters
        response =  if filters.nil?
                      @@conn.describe_reserved_instances_offerings.body['reservedInstancesOfferingsSet']
                    else
                      @@conn.describe_reserved_instances_offerings(filters).body['reservedInstancesOfferingsSet']
                    end
        Formatador.display_table(response)
      end

      def list_filters
        filters = [
          {:filter_name => "availability-zone", :desc => "Availability Zone where the Reserved Instance can be used", :availability => "Both"},
          {:filter_name => "duration", :desc => "Duration of the Reserved Instance (e.g., one year or three years), in seconds", :availability => "Both"},
          {:filter_name => "fixed-price", :desc => "Purchase price of the Reserved Instance", :availability => "Both"},
          {:filter_name => "instance-type", :desc => "Instance type on which the Reserved Instance can be used", :availability => "Both"},
          {:filter_name => "product-description", :desc => "Reserved Instance description", :availability => "Both"},
          {:filter_name => "reserved-instances-id", :desc => "Reserved Instance's ID", :availability => "Only ReservedInstances"},
          {:filter_name => "reserved-instances-offering-id", :desc => "Reserved Instances offering ID", :availability => "Only reservedInstancesOfferingsSet"},
          {:filter_name => "start", :desc => "Time the Reserved Instance purchase request was placed", :availability => "Only ReservedInstances"},
          {:filter_name => "state", :desc => "State of the Reserved Instance", :availability => "Only ReservedInstances"},
          {:filter_name => "tag-key", :desc => "Key of a tag assigned to the resource", :availability => "Only ReservedInstances"}, #This filter is independent of the tag-value filter. For example, if you use both the filter tag-key=Purpose and the filter tag-value=X, you get any resources assigned both the tag key Purpose and the tag value X
          {:filter_name => "tag-value", :desc => "Value of a tag assigned to the resource", :availability => "Only ReservedInstances"}, #This filter is independent of the tag-key filter.
          {:filter_name => "usage-price", :desc => "Usage price of the Reserved Instance, per hour", :availability => "Both"},
        ]
        Formatador.display_table(filters, [:filter_name, :desc, :availability])
      end

      def purchase options
        @@conn.purchase_reserved_instances_offering(options[:reserved_instances_offering_id], options[:instance_count])
      end
    end # => ReservedInstances

    class Spot
      def initialize connection, options = {}
        @@conn = connection
      end

      def describe_spot_requests
        @@conn.spot_requests.table
      end

      def describe_spot_datafeed_subscription
        @@conn.describe_spot_datafeed_subscription
      end

      def describe_spot_price_history filters
        puts filters
        response =  if filters.nil?
                      @@conn.describe_spot_price_history.body['spotPriceHistorySet']
                    else
                      @@conn.describe_spot_price_history(filters).body['spotPriceHistorySet']
                    end
        Formatador.display_table(response)
      end

      def list_filters
        filters = [
          {:filter_name => "instance-type", :desc => "Type of instance"},
          {:filter_name => "product-description", :desc => "Product description for the Spot Price"},
          {:filter_name => "spot-price", :desc => "Spot Price. The value must match exactly (or use wildcards; greater than or less than comparison is not supported)"},
          {:filter_name => "timestamp", :desc => "Timestamp of the Spot Price history, e.g., 2010-08-16T05:06:11.000Z. You can use wildcards (* and ?)"},
        ]
        Formatador.display_table(filters, [:filter_name, :desc])
      end

      def create_spot_datafeed_subsription bucket, prefix
        @@conn.create_spot_datafeed_subscription(bucket, prefix)
      end

      def delete_spot_datafeed_subsription
        @@conn.delete_spot_datafeed_subscription
      end

      def request_spot_instances options
        sr = @@conn.spot_requests.create(options)
        puts "Created spot request: #{sr.id}"
      end

      def cancel_spot_instance_requests sid
        sr = @@conn.spot_requests.get(sid)
        abort "Cannot find spot request with id: #{sid}" unless sr
        sr.destroy
        puts "Deleted spot request: #{sid}"
      end
    end # => Spot

    class Vpc
      def initialize connection, options = {}
        @@conn = connection
      end

      def list
        @@conn.vpcs.table
      end

      def create options
        vpc = @@conn.vpcs.create(options)
        puts "Created VPC: #{vpc.id}"
      end

      def delete vpc_id
        vpc = @@conn.vpcs.get(vpc_id)
        abort "cannot find vpc: #{vpc_id}" unless vpc
        vpc.destroy
        puts "Deleted VPC : #{vpc_id}"
      end
    end # => Vpc

    class Subnet
      def initialize connection, options = {}
        @@conn = connection
      end

      def list
        @@conn.subnets.table
      end

      def create options
        subnet = @@conn.subnets.create(options)
        puts "Created Subnet: #{subnet.id}"
      end

      def delete subnet_id
        subnet = @@conn.subnets.get(subnet_id)
        abort "Cannot find subnet: #{subnet_id}" unless subnet
        subnet.destroy
        puts "Deleted subnet: #{subnet_id}"
      end
    end # => Subnet

    class NetworkAcl
      def initialize connection, options = {}
        @@conn = connection
      end

      def list
        puts "Listing Network Acls"
      end

    end # => NetworkAcl

    class NetworkInterfaces
      def initialize connection, options = {}
        @@conn = connection
      end

      def list
        @@conn.network_interfaces.table
      end

      def create options
        nic = @@conn.network_interfaces.create(options)
        puts "Create network interface #{nic.network_interface_id}"
      end

      def delete nic_id
        nic = @@conn.network_interfaces.get(nic_id)
        abort "Cannot find nic with id: #{nic_id}" unless nic
        nic.destroy
        puts "Deleted network interface #{nic_id}"
      end

      def attach nic_id, instance_id, device_index
        @@conn.attach_network_interface(nic_id, instance_id, device_index)
        puts "Attached Network Interface: #{nic_id} to instance: #{instance_id}"
      end

      def deattach attachement_id, force
        @@conn.detach_network_interface attachement_id, force
        puts "Deattached Network Interface with attachement_id: #{attachement_id}"
      end

      def modify_attribute options
        case options[:attribute]
        when 'description'
          @@conn.modify_network_interface_attribute(options[:network_interface_id], 'description', options[:description])
        when 'groupSet'
          @@conn.modify_network_interface_attribute(options[:network_interface_id], 'groupSet', options[:group_set])
        when 'sourceDestCheck'
          @@conn.modify_network_interface_attribute(options[:network_interface_id], 'sourceDestCheck', options[:source_dest_check])
        when 'attachment'
          @@conn.modify_network_interface_attribute(options[:network_interface_id], 'attachment', options[:attachment])
        else
          abort "Invalid attribute: #{options[:attribute]}"
        end
      end
    end # => NetworkInterfaces

    class InternetGateways
      def initialize connection, options = {}
        @@conn = connection
      end

      def list
        @@conn.internet_gateways.table
      end

      def create
        gw = @@conn.internet_gateways.create
        puts "Created Internet Gateway: #{gw.id}"
      end

      def delete gwid
        gw = @@conn.internet_gateways.get(gwid)
        gw.destroy
        puts "Deleted Internet Gateway: #{gwid}"
      end

      def attach gwid, vpcid
        @@conn.internet_gateways.attach(gwid, vpcid)
        puts "Attached InternetGateway: #{gwid} to VPC: #{vpcid}"
      end

      def deattach gwid, vpcid
        @@conn.internet_gateways.deattach(gwid, vpcid)
        puts "Deattached InternetGateway: #{gwid} from VPC: #{vpcid}"
      end
    end # => InternetGateways

    class Dhcp
      def initialize connection, options = {}
        @@conn = connection
      end

      def list
        @@conn.dhcp_options.table
      end

      def create options
        @@conn.dhcp_options.create(options)
      end

      def delete dhcp_id
        dhcp = @@conn.dhcp_options(dhcp_id)
        dhcp.destroy
      end

      def associate dhcp_ic, vpc_id
        @@conn.dhcp_options.attach(dhcp_id, vpc_id)
      end
    end # => Dhcp

  end
end