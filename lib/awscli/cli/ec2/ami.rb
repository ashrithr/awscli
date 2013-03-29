module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class Ami < Thor

        desc "list", "List Images"
        method_option :filter, :aliases => "-f", :type => :hash, :desc => "filter the images based on filters"
        method_option :amazon_owned, :aliases => "-a", :type => :boolean, :default => false, :desc => "lists amazon owned images"
        method_option :show_filters, :aliases => "-s", :type => :boolean, :default => false, :desc => "filters available"
        def list
          create_ec2_object
          if options[:amazon_owned]
            @ec2.list_amazon
          elsif options[:show_filters]
            @ec2.show_filters
          else
            @ec2.list options[:filter]
          end
        end

        desc "create", "Create a bootable EBS volume AMI, from instance specified"
        method_option :instance_id, :aliases => "-i", :type => :string, :required => true, :desc => "Instance used to create image"
        method_option :name, :aliases => "-n", :type => :string, :default => "awscli_image_#{Time.now.to_i}", :desc => "Name to give image"
        method_option :desc, :aliases => "-d", :type => :string, :default => "awscli_image-created_at-#{Time.now.to_i}", :desc => "Description of image"
        method_option :no_reboot, :aliases => "-r", :type => :boolean, :default => false, :desc => "Optional, whether or not to reboot the image when making the snapshot"
        def create
          create_ec2_object
          @ec2.create_image_from_instance options
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
          @ec2 = Awscli::EC2::Ami.new($ec2_conn)
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::Ami, :ami, 'ami [COMMAND]', 'EC2 AMI Management'

      end
    end
  end
end