module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class Ebs < Thor

        desc "list", "List ELastic Block Storages"
        method_option :snapshots, :aliases => "-s", :type => :boolean, :default => false, :desc => "list snapshots"
        def list
          create_ec2_object
          @ec2.list
        end

        desc "create", "Create a EBS Volume"
        method_option :availability_zone, :aliases => "-z", :required => true, :banner => "ZONE", :type => :string, :desc => "Name of the availability zone to create the voulume in"
        method_option :size, :aliases => "-s", :required => true, :type => :numeric, :desc => "Size of the volume to create (in GB)"
        method_option :snapshot_id, :aliases => "-i", :banner => "ID", :type => :string, :desc => "Snapshot ID from which to create volume from"
        method_option :device, :aliases => "-d", :type => :string, :desc => "how the volume is exposed(in unix '/dev/sdx', in windows 'xvdf')"
        def create
          create_ec2_object
          @ec2.create options
        end

        desc "attach_volume", "Attach a volume to instance"
        method_option :instance_id, :aliases => "-i", :banner => "ID", :type => :string, :desc => "instance id to attach the volume to"
        method_option :volume_id, :aliases => "-v", :banner => "VID", :type => :string, :desc => "volume id to attach"
        method_option :device, :aliases => "-d", :type => :string, :desc => "how the volume is exposed(in unix '/dev/sdx', in windows 'xvdf')"
        def attach_volume
          create_ec2_object
          @ec2.attach_volume options
        end

        desc "detach_voulme", "Detach a volume from instance"
        method_option :volume_id, :aliases => "-v", :banner => "VID", :type => :string, :desc => "volume id to attach"
        method_option :force, :aliase => "-f", :type => :boolean, :default => false, :desc => "force detaches the volume"
        def detach_volume
          create_ec2_object
          @ec2.detach_volume options
        end

        desc "delete", "Delete Volume"
        method_option :volume_id, :aliases => "-v", :banner => "VID", :required => true, :type => :string, :desc => "volume id to delete"
        def delete
          #ask if the user is sure about deleting the volume which leads to data loss or can make a snapshot before deleting it
          create_ec2_object
          @ec2.delete_volume options
        end

        desc "create_snapshot", "Create a snapshot from volume"
        method_option :volume_id, :aliases => "-v", :banner => "VID", :required => true, :type => :string, :desc => "volume to make a snapshot from"
        def create_snapshot
          create_ec2_object
          @ec2.create_snapshot
        end

        desc "copy_snapshot", "Copy a snapshot to a different region"
        method_option :source_region, :aliases => "-s", :banner => "REGION", :required => true, :type => :string, :desc => "Region to move it from"
        method_option :snapshot_id, :aliases => "-i", :banner => "ID", :required => true, :type => :string, :desc => "Id of the snapshot"
        def copy_snapshot
          create_ec2_object
          @ec2.copy_snapshot
        end

        desc "delete_snapshot", "Delete SnapShot"
        def delete_snapshot
          create_ec2_object
          @ec2.delete_snapshot
        end

        private

        def create_ec2_object
          puts "ec2 Establishing Connetion..."
          $ec2_conn = Awscli::Connection.new.request_ec2
          puts "ec2 Establishing Connetion... OK"
          @ec2 = Awscli::EC2::Ebs.new($ec2_conn)
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::Ebs, :ebs, 'ebs [COMMAND]', 'EC2 EBS Management'

      end
    end
  end
end