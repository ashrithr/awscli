module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class MonitoringInstances < Thor

        desc "monitor", "Monitor specified instance(s)"
        method_option :instance_ids, :aliases => "-i", :type => :array, :required => true, :desc => "Instances Ids to monitor"
        def monitor
          create_ec2_object
          @ec2.monitor options
        end

        desc "unmonitor", "UnMonitor specified instance(s)"
        method_option :instance_ids, :aliases => "-i", :type => :array, :required => true, :desc => "Instances Ids to monitor"
        def unmonitor
          create_ec2_object
          @ec2.unmonitor options
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
          @ec2 = Awscli::EC2::Monitoring.new($ec2_conn)
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::MonitoringInstances, :mont, 'mont [COMMAND]', 'EC2 Instances Monitoring Management'

      end
    end
  end
end