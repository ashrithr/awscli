module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class Instances < Thor

        desc "list", "ec2_describe_instances"
        long_desc <<-LONGDESC
         List and describe your instances
         The INSTANCE parameter is the instance ID(s) to describe.
         If unspecified all your instances will be returned.
        LONGDESC
        def list
          puts "Listing Instances"
        end

        #not necessary
        desc "diatt", "ec2_describe_instance_attribute"
        def diatt
        end

        desc "miatt", "ec2_modify_instance_attribute"
        long_desc <<-LONGDESC
          Modifies an instance attribute. Only one attribute can be specified per call.
        LONGDESC
        def miatt
        end

        desc "riatt", "ec2_reset_instance_attribute"
        long_desc <<-LONGDESC
          Resets an instance attribute to its initial value. Only one attribute can be specified per call.
        LONGDESC
        def riatt
        end

        desc "dins", "ec2_describe_instance_status"
        long_desc <<-LONGDESC
         Describe the status for one or more instances.
         Checks are performed on your instances to determine if they are
         in running order or not. Use this command to see the result of these
         instance checks so that you can take remedial action if possible.

         There are two types of checks performed: INSTANCE and SYSTEM.
         INSTANCE checks examine the health and reachability of the
         application environment. SYSTEM checks examine the health of
         the infrastructure surrounding your instance.
        LONGDESC
        def dins
        end

        desc "import", "ec2_import_instance"
        long_desc <<-LONGDESC
          Create an import instance task to import a virtual machine into EC2
          using meta_data from the given disk image. The volume size for the
          imported disk_image will be calculated automatically, unless specified.
        LONGDESC
        def import
        end

        desc "reboot", "ec2_reboot_instances"
        long_desc <<-LONGDESC
         Reboot selected running instances.
         The INSTANCE parameter is an instance ID to reboot.
        LONGDESC
        def reboot
        end

        desc "create", "ec2_run_instances"
        long_desc <<-LONGDESC
          Launch a number of instances of a specified AMI.
        LONGDESC
        def create
        end

        desc "start", "ec2_start_instances"
        long_desc <<-LONGDESC
          Start selected running instances.
        LONGDESC
        def start
        end

        desc "stop", "ec2_stop_instances"
        long_desc <<-LONGDESC
          Stop selected running instances.
        LONGDESC
        def stop
        end

        desc "kill", "ec2_terminate_instances"
        long_desc <<-LONGDESC
          Terminate selected running instances
        LONGDESC
        def kill
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::Instances, :instances, 'instances [COMMAND]', 'EC2 Instance Management'

      end
    end
  end
end