module AwsCli
  module CLI
    require 'awscli/cli'
    require 'awscli/connection'
    require 'awscli/ec2'
    class Ec2 < Thor

      method_option :dr, :type => :numeric, :desc => "repeat greeting X times", :default => 3
      desc "describe_ec2_instances", "list instances"
      def describe_ec2_instances
        p ec2_object.inspect
      end

      private

      def ec2_object
        puts "ec2 Establishing Connetion..."
        $ec2_conn = Awscli::Connection.new.request_ec2
        puts $ec2_conn
        puts "ec2 Establishing Connetion... OK"
        @ec2 = Awscli::EC2::EC2.new($ec2_conn)
      end

      AwsCli::Cli.register AwsCli::CLI::Ec2, :ec2, 'ec2 [COMMAND]', 'Elastic Cloud Compute Interface'
    end
  end
end