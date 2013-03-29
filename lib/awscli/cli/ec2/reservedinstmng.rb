module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class ReservedInstances < Thor

        desc "list", "List ReservedInstances"
        #TODO add filters
        method_option :filters, :aliases => "-f", :type => :hash, :desc => "List of filters to limit results with"
        method_option :offerings, :aliases => "-o", :type => :boolean, :default => false, :desc => "Describe all or specified reserved instances offerings"
        method_option :list_filters, :aliases => "-l", :type => :boolean, :default => false, :desc => "List availble filters that you can be used to limit results"
        def list
          create_ec2_object
          if options[:offerings]
            @ec2.list_offerings options[:filters]
          elsif options[:list_filters]
            @ec2.list_filters
          else
            @ec2.list options[:filters]
          end
        end

        desc "purchase", "Purchases a Reserved Instance for use with your account"
        method_option :reserved_instances_offering_id, :aliases => "-i", :type => :string, :desc => "ID of the Reserved Instance offering you want to purchase"
        method_option :instance_count, :aliases => "-c", :type => :numeric, :default => 1, :desc => "The number of Reserved Instances to purchase"
        def purchase
          create_ec2_object
          @ec2.purchase options
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
          @ec2 = Awscli::EC2::ReservedInstances.new($ec2_conn)
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::ReservedInstances, :resv, 'resv [COMMAND]', 'EC2 ReservedInstances Management'

      end
    end
  end
end