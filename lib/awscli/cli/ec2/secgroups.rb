module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class SecGroups < Thor

        desc "list", "List Security Groups"
        method_option :show_ip_permissions, :aliases => "-p", :type => :boolean, :default => false, :desc => "Enabling this flag will show ip permissions as well"
        def list
          create_ec2_object
          @ec2.list_secgroups options
        end

        desc "create", "Create New Security Group"
        method_option :name, :aliases => "-n", :required => true, :banner => "NAME", :type => :string, :desc => "Name of the security group to create"
        method_option :description, :aliases => "-d", :banner => "DESC", :type => :string, :desc => "Description of the group"
        method_option :vpc_id, :aliases => "-v", :banner => "VPCID", :type => :string, :desc => "VPC ID to attach the security group to"
        def create
          create_ec2_object
          @ec2.create_securitygroup options
        end

        desc "authorize", "Add a rule to existing Security Group"
        method_option :group_id, :aliases => "-g", :required => true, :banner => "SGID", :type => :string, :desc => "ID of the security group to add a rule to"
        method_option :protocol_type, :aliases => "-t", :required => true, :required => true, :banner => "TCP|UDP|ICMP", :type => :string, :desc => "Protocol Type to use for the rule"
        method_option :start_port, :aliases => "-s", :required => true, :banner => "NUM", :type => :numeric, :desc => "Start of port range (or -1 for ICMP wildcard)"
        method_option :end_port, :aliases => "-e", :required => true, :banner => "NUM", :type => :numeric, :desc => "End of port range (or -1 for ICMP wildcard)"
        method_option :cidr, :aliases => "-c", :type => :string, :default => "0.0.0.0/0", :desc => "CIDR range"
        def authorize
          create_ec2_object
          @ec2.authorize_securitygroup options
        end

        desc "revoke", "Remove a rule from security group"
        method_option :group_id, :aliases => "-g", :required => true, :banner => "SGID", :type => :string, :desc => "ID of the security group to add a rule to"
        method_option :protocol_type, :aliases => "-t", :required => true, :required => true, :banner => "TCP|UDP|ICMP", :type => :string, :desc => "Protocol Type to use for the rule"
        method_option :start_port, :aliases => "-s", :required => true, :banner => "NUM", :type => :numeric, :desc => "Start of port range (or -1 for ICMP wildcard)"
        method_option :end_port, :aliases => "-e", :required => true, :banner => "NUM", :type => :numeric, :desc => "End of port range (or -1 for ICMP wildcard)"
        method_option :cidr, :aliases => "-c", :type => :string, :default => "0.0.0.0/0", :desc => "CIDR range"
        def revoke
          create_ec2_object
          @ec2.revoke_securitygroup options
        end

        desc "delete", "Delete existing security group"
        method_option :group_id, :aliases => "-g", :required => true, :banner => "SGID", :type => :string, :desc => "ID of the security group to add a rule to"
        def delete
          create_ec2_object
          @ec2.delete_securitygroup options
        end

        private

        def create_ec2_object
          puts "ec2 Establishing Connetion..."
          $ec2_conn = Awscli::Connection.new.request_ec2
          puts "ec2 Establishing Connetion... OK"
          @ec2 = Awscli::EC2::SecGroups.new($ec2_conn)
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::SecGroups, :sg, 'sg [COMMAND]', 'EC2 Security Groups Management'

      end
    end
  end
end