module AwsCli
  module CLI
    module EC2
      module VPC
        require 'awscli/cli/ec2/vpc'
        class RouteTables < Thor

          desc "list", "List available route tables"
          method_option :route_table_id, :aliases => "-r", :type => :string, :desc => "Comma seperated list of route table ID(s) to list"
          def list
            create_ec2_object
            @ec2.list options
          end

          desc "create", "Creates a route table for the specified VPC. After you create a route table, you can add routes and associate the table with a subnet."
          method_option :vpc_id, :aliases => "-v", :type => :string, :required => true, :desc => "The ID of the VPC"
          def create
            create_ec2_object
            @ec2.create options
          end

          desc "create_route", "Creates a route in a route table within a VPC"
          method_option :route_table_id, :aliases => "-r", :type => :string, :required => true, :desc => "The ID of the route table for the route"
          method_option :dest_cidr, :aliases => "-d", :type => :string, :required => true, :desc => "The CIDR address block used for the destination match, routing decisions are based on the most specific match"
          method_option :gateway_id, :aliases => "-g", :type => :string, :desc => "The ID of an Internet gateway attached to your VPC"
          method_option :instance_id, :aliases => "-i", :type => :string, :desc => "ID of a NAT instance in your VPC. The operation fails if you specify an instance ID unless exactly one network interface is attached"
          method_option :net_interface_id, :aliases => "-n", :type => :string, :desc => "ID of a network interface"
          def create_route
            if options[:gateway_id] || options[:instance_id] || options[:net_interface_id]
              create_ec2_object
              @ec2.create_route(options)
            else
              Formatador.display_line("[red]Error: [/]Any one of the following options (--gateway-id, --instance-id, --net-interface-id) is requried")
            end
          end

          desc "delete", "Deletes the specified route table, you must disassociate the route table from any subnets before you can delete it"
          method_option :route_table_id, :aliases => "-r", :type => :string, :required => true, :desc => "The ID of the route table"
          def delete
            create_ec2_object
            @ec2.delete(options)
          end

          desc "delete_route", "Deletes the specified route from the specified route table"
          method_option :route_table_id, :aliases => "-r", :type => :string, :required => true, :desc => "The ID of the route table"
          method_option :dest_cidr, :aliases => "-d", :type => :string, :required => true, :desc => "The CIDR range for the route(the value you specify must match the CIDR for the route exactly)"
          def delete_route
            create_ec2_object
            @ec2.delete_route(options)
          end

          desc "associate_route_table", "Associates a subnet with a route table (the subnet and route table must be in the same VPC)"
          method_option :route_table_id, :aliases => "-r", :type => :string, :required => true, :desc => "The ID of the route table"
          method_option :subnet_id, :aliases => "-s", :type => :string, :required => true, :desc => "The ID of the subnet"
          def associate_route_table
            create_ec2_object
            @ec2.associate_route_table(options)
          end

          desc "disassociate_route_table", "Disassociates a subnet from a route table"
          method_option :association_id, :aliases => "-a", :type => :string, :required => true, :desc => "The association ID representing the current association between the route table and subnet"
          def disassociate_route_table
            create_ec2_object
            @ec2.disassociate_route_table(options)
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
            @ec2 = Awscli::EC2::RouteTable.new($ec2_conn)
          end

          AwsCli::CLI::EC2::Vpc.register AwsCli::CLI::EC2::VPC::RouteTables, :routetable, 'routetable [COMMAND]', 'VPC RouteTable Management'
        end
      end
    end
  end
end