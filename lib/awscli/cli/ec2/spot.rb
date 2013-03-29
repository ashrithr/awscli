module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class SpotInstancesManagement < Thor

        desc "list", "List spot requests or spot data feed subscription"
        method_option :describe_spot_datafeed_subscription, :aliases => "-s", :type => :boolean, :default => false, :desc => "Describe spot data feed subscription"
        method_option :price_history, :aliases => "-p", :type => :boolean, :default => false, :desc => "Describe spot price history"
        method_option :filters, :aliases => "-f", :type => :hash, :desc => "List of filters to limit results with"
        method_option :list_filters, :aliases => "-l", :type => :boolean, :default => false, :desc => "List the available filters"
        def list
          create_ec2_object
          if options[:describe_spot_datafeed_subscription]
            @ec2.describe_spot_datafeed_subscription
          elsif options[:price_history]
            @ec2.describe_spot_price_history options[:filters]
          elsif options[:list_filters]
            @ec2.list_filters
          else
            @ec2.describe_spot_requests
          end
        end

        desc "create_spot_datafeed", "Create a spot datafeed subscription"
        method_option :bucket, :aliases => "-b", :type => :string, :required => true, :desc => "bucket name to store datafeed in"
        method_option :prefix, :aliases => "-p", :type => :string, :required => true, :desc => "prefix to store data with"
        def create_spot_datafeed
          create_ec2_object
          @ec2.create_spot_datafeed_subsription options[:bucket], options[:prefix]
        end

        desc "delete_spot_datafeed", "Delete a spot datafeed subscription"
        def delete_spot_datafeed
          create_ec2_object
          @ec2.delete_spot_datafeed_subsription
        end

        desc "create", "Request spot instances"
        method_option :price, :aliases => "-p", :type => :string, :required => true, :desc => "The maximum hourly price for any Spot Instance launched to fulfill the request"
        method_option :image_id, :aliases => "-a", :type => :string, :required => true, :desc => "ami id to use"
        method_option :flavor_id, :aliases => "-t", :type => :string, :required => true, :desc => "type of the instance to use"
        method_option :key_name, :aliases => "-k", :type => :string, :required => true, :desc => "The name of the key pair"
        method_option :instance_count, :aliases => "-c", :type => :numeric, :default => 1, :desc => "The maximum number of Spot Instances to launch"
        method_option :request_type, :type => :string, :desc => "The Spot Instance request type, Valid Values:one-time | persistent"
        method_option :valid_from, :type => :string, :banner => "DATETIME", :desc => "Start date of the request" #If this is a one-time request, the request becomes active at this date and time and remains active until all instances launch, the request expires, or the request is canceled If the request is persistent, the request becomes active at this date and time and remains active until it expires or is canceled.
        method_option :valid_until, :type => :string, :banner => "DATETIME", :desc => "End date of the request" #If this is a one-time request, the request remains active until all instances launch, the request is canceled, or this date is reached. If the request is persistent, it remains active until it is canceled or this date and time is reached
        method_option :launch_group, :type => :string, :default => "awscli_spot_group_#{Time.now.to_i}",:desc => "The instance launch group. Launch groups are Spot Instances that launch together and terminate together"
        method_option :availability_zone_group, :type => :string, :desc => "The Availability Zone group. If you specify the same Availability Zone group for all Spot Instance requests, all Spot Instances are launched in the same Availability Zone"
        method_option :groups, :type => :array, :default => ["default"], :desc => "Name of the security group"
        method_option :user_data, :type => :string, :desc => "MIME, Base64-encoded user data to make available to the instances"
        method_option :availability_zone, :type => :string, :desc => "The placement constraints (Availability Zone) for launching the instances"
        method_option :block_device_mapping, :type => :string, :desc => "ebs mappings"
        method_option :subnet_id, :type => :string, :desc => "subnet id use if vpc"
        method_option :ebs_optimized, :type => :boolean, :desc => "whether to enable ebs optimization"
        method_option :monitoring, :type => :boolean, :deafult => false, :desc => "Enables monitoring for the instance"
        method_option :tags, :type => :string, :desc => "tags for the instances"
        def create
          create_ec2_object
          @ec2.request_spot_instances options
        end

        desc "cancel", "Cancel spot instance requests"
        def cancel
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
          @ec2 = Awscli::EC2::Spot.new($ec2_conn)
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::SpotInstancesManagement, :spot, 'spot [COMMAND]', 'EC2 Spot Instances Management'

      end
    end
  end
end