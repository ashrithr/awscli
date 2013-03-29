module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class Eip < Thor

        desc "list", "List Elastic IPs"
        def list
          puts "Listing EIPs"
          create_ec2_object
          @ec2.list
        end

        desc "create", "Create Elastic IP"
        def create
          create_ec2_object
          @ec2.create
        end

        desc "delete", "Delete Elastic IP"
        method_option :eip, :aliases => "-e", :required => true, :banner => "IP", :type => :string, :desc => "Elastic IP to delete"
        def delete
          create_ec2_object
          @ec2.delete options
        end

        desc "associate", "Associate EIP with an Instance"
        method_option :eip, :aliases => "-e", :required => true, :banner => "IP", :type => :string, :desc => "Elastic IP to associate"
        method_option :instance_id, :aliases => "-i", :required => true, :banner => "ID", :type => :string, :desc => "Instance ID to which to associate EIP"
        def associate
          create_ec2_object
          @ec2.associate options
        end

        desc "disassociate", "Disassociate EIP from an instance"
        method_option :eip, :aliases => "-e", :required => true, :banner => "IP", :type => :string, :desc => "Elastic IP to disassociate"
        def disassociate
          create_ec2_object
          @ec2.disassociate options
        end

        private

        def create_ec2_object
          puts "ec2 Establishing Connetion..."
          $ec2_conn = if parent_options[:region]
                        Awscli::Connection.new.request_ec2(parent_options[:region])
                      else
                        Awscli::Connection.new.request_ec2
                      end
          puts "ec2 Establishing Connetion... OK"
          @ec2 = Awscli::EC2::Eip.new($ec2_conn)
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::Eip, :eip, 'eip [COMMAND]', 'EC2 EIP Management'

      end
    end
  end
end