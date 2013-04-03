module AwsCli
  module CLI
    require 'awscli/cli'
    require 'awscli/connection'
    require 'awscli/emr'
    class Emr < Thor
      class_option :region, :type => :string, :desc => "region to connect to", :default => 'us-west-1'

      desc 'list [OPTIONS]', 'returns a yaml dump of job flows that match all of the supplied parameters'
      #method_option :created_after, :desc => 'Return only job flows created after this date and time'
      #method_option :created_before, :desc => 'Return only job flows created before this date and time'
      method_option :job_flow_ids, :aliases => '-j', :type => :array, :desc => 'Return only job flows whose job flow ID is contained in this list'
      method_option :job_flow_status, :aliases => '-s' ,:type => :array, :desc => 'Return only job flows whose state is contained in this list, Valid Values: RUNNING | WAITING | SHUTTING_DOWN | STARTING'
      method_option :table, :aliases => '-t', :type => :boolean, :default => false, :desc => 'Prints out table format'
      def list
        if options[:job_flow_status]
          abort 'Invalid job flow status' unless %w(RUNNING WAITING SHUTTING_DOWN STARTING).each_cons(options[:job_flow_status].size).include? options[:job_flow_status]
        end
        create_emr_object
        @emr.list options
      end

      desc 'delete', 'shuts a list of job flows down'
      method_option :job_flow_ids, :aliases => '-j', :type => :array, :required => true, :desc => 'list of strings that uniquely identify the job flows to delete'
      def delete
        create_emr_object
        @emr.delete options[:job_flow_ids]
      end

      desc 'add_instances [OPTIONS]', 'adds an instance group to a running cluster'
      long_desc <<-DESC
        USAGE:

        awscli emr add_instances -j j-31HK0PWNQ2JKH -c 2 -r TASK -t m1.small -n computegroup -b 0.2
      DESC
      method_option :job_flow_id, :aliases => '-j', :banner => 'ID', :desc => 'Job flow in which to add the instance groups'
      method_option :bid_price, :aliases => '-b', :desc => 'Bid price for each Amazon EC2 instance in the instance group when launching nodes as Spot Instances'
      method_option :instance_count, :aliases => '-c', :banner => 'COUNT', :type => :numeric, :desc => 'Target number of instances for the instance group'
      method_option :instance_role, :aliases => '-r', :banner => 'ROLE', :desc => 'The role of the instance group in the cluster, Valid values: MASTER | CORE | TASK'
      method_option :instance_type, :aliases => '-t', :banner => 'TYPE', :desc => 'The Amazon EC2 instance type for all instances in the instance group'
      method_option :name, :aliases => '-n', :desc => 'Friendly name given to the instance group'
      def add_instances
        if !options[:job_flow_id] and !options[:instance_count] and !options[:instance_role] and !options[:instance_type]
          puts 'These options are required --job-flow-id, --instance-count, --instance-role and --instance-type'
          exit
        end
        abort 'Invalid Instance Role' unless %w(MASTER CORE TASK).include?(options[:instance_role])
        create_emr_object
        @emr.add_instance_group options
      end

      desc 'modify_instances [OPTIONS]', 'modifies the number of nodes and configuration settings of an instance group'
      method_option :instance_count, :aliases => '-c', :banner => 'COUNT', :desc => 'Target size for instance group'
      method_option :instance_group_id, :aliases => '-g', :banner => 'ID', :desc => 'Unique ID of the instance group to expand or shrink'
      def modify_instances
        if !options[:instance_count] and !options[:instance_group_id]
          puts 'These options are required --instance-count and --instance-group-id'
          exit
        end
        create_emr_object
        @emr.modify_instance_group options
      end

      desc 'termination_protection [OPTIONS]', 'locks a job flow so the Amazon EC2 instances in the cluster cannot be terminated by user intervention'
      method_option :job_flow_ids, :aliases => '-j', :banner => 'ID(S)', :required => true, :type => :array, :desc => 'list of strings that uniquely identify the job flows to protect'
      method_option :termination_protection, :aliases => '-t', :type => :boolean, :default => false, :desc => 'indicates whether to protect the job flow, if set temination protection is enabled if left alone termination protection is turned off'
      def termination_protection
        create_emr_object
        @emr.set_termination_protection options[:job_flow_ids], options[:termination_protection]
      end

      desc 'create [OPTIONS]', 'creates and starts running a new job flow'
      method_option :
      def create

      end

      private

      def create_emr_object
        puts 'EMR Establishing Connetion...'
        $emr_conn =  Awscli::Connection.new.request_emr
        puts 'EMR Establishing Connetion... OK'
        @emr = Awscli::Emr::EMR.new($emr_conn)
      end

      AwsCli::Cli.register AwsCli::CLI::Emr, :emr, 'emr [COMMAND]', 'AWS Elastic Map Reduce Interface'
    end
  end
end