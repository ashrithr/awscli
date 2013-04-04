module AwsCli
  module CLI
    require 'awscli/cli'
    require 'awscli/connection'
    require 'awscli/emr'
    class Emr < Thor
      class_option :region, :type => :string, :desc => "region to connect to", :default => 'us-west-1'

      desc 'usage', 'show the usage examples'
      def usage
        File.open(File.dirname(__FILE__) + '/UsageExamples/emr') do |file|
          puts file.read
        end
      end

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
      #TODO: update Long Desc
      #TODO: add hbase install & backup
      long_desc <<-DESC
      DESC
      method_option :name, :aliases => '-n', :desc => 'The name of the job flow'
      #method_option :ami_version, :default => 'latest', :desc => 'The version of the Amazon Machine Image (AMI) to use when launching Amazon EC2 instances in the job flow'
      #method_option :additional_info, :desc => 'A JSON string for selecting additional features.'
      method_option :log_uri, :desc => 'Specifies the location in Amazon S3 to write the log files of the job flow.' #If a value is not provided, logs are not created
      method_option :instance_ec2_key_name, :aliases => '-k', :desc => 'Specifies the name of the Amazon EC2 key pair that can be used to ssh to the master node as the user called hadoop'
      method_option :instance_ec2_subnet_id, :desc => 'Amazon VPC subnet where you want the job flow to launch'
      method_option :hadoop_version, :default => '1.0.3',:desc => 'Specifies the Hadoop version to install for the job flow'
      method_option :instance_count, :type => :numeric, :desc => 'The number of Amazon EC2 instances used to execute the job flow'
      method_option :alive, :type => :boolean, :default => false, :desc => 'Job flow stays running even though it has executed all its steps'
      method_option :master_instance_type, :desc => 'The EC2 instance type of the master node'
      method_option :slave_instance_type, :desc => 'The EC2 instance type of the slave nodes'
      method_option :termination_protection, :type => :boolean, :default => false, :desc => 'Specifies whether to lock the job flow to prevent the Amazon EC2 instances from being terminated by API call'
      method_option :bootstrap_actions, :aliases => '-b', :type => :array, :desc => 'Add bootstrap action script. Format => "name,bootstrap_action_path,bootstrap_action_args"'
      method_option :instance_groups, :aliases => '-g', :type => :array, :desc => 'Add instance groups. Format => "instance_count,instance_role(MASTER | CORE | TASK),instance_type,name,bid_price" see help for usage'
      method_option :custom_jar_steps, :aliases => '-s', :type => :array, :desc => 'Add a step that runs a custom jar. Format=> "jar_path(s3)*,main_class*,name_of_step,action_on_failure(TERMINATE_JOB_FLOW | CANCEL_AND_WAIT | CONTINUE),arg1,agr2,arg3"'
      method_option :hive_interactive, :type => :boolean, :default => false, :desc => 'Add a step that sets up the job flow for an interactive (via SSH) hive session'
      method_option :pig_interactive, :type => :boolean, :default => false, :desc => 'Add a step that sets up the job flow for an interactive (via SSH) pig session'
      method_option :hive_steps, :type => :array, :desc => 'Add a step that runs a Hive script. Format=> script_path(s3)*,input_path(s3),output_path(s3),"-d args1","-d args2","-d arg3"'
      method_option :pig_steps, :type => :array, :desc => 'Add a step that runs a Pig script. Format=> script_path(s3)*,input_path(s3),output_path(s3),"-p args1","-p args2","-p arg3"'
      method_option :streaming_steps, :type => :array, :desc => 'Add a step that performs hadoop streaming. Format=> input*,output*,mapper*,reducer*,extra_arg1,extra_arg2'
      method_option :hbase_install, :type => :boolean, :default => false, :desc => 'Install hbase on the cluster'
      method_option :hbase_backup_restore, :desc => 'Specify whether to preload the HBase cluster with data stored in Amazon S3. Format=> path(s3)*,version'
      method_option :hbase_backup_schedule, :desc => 'Specify whether to schedule automatic incremental backups. Format=> frequency*,frequency_unit*(Days|Hours|Mins),path(s3)*,start_time*(now|date)'
      method_option :hbase_consistent_backup, :type => :boolean, :default => false, :desc => 'Perform a consistent backup'
      def create
        if !options[:name]
          puts 'These options are required --name'
          exit
        end
        create_emr_object
        @emr.create_job_flow options
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