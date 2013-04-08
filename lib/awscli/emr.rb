module Awscli
  module Emr
    class EMR
      def initialize(connection)
        @conn = connection
      end

      def list options
        validate_job_ids options[:job_flow_ids] if options[:job_flow_ids]
        opts = Marshal.load(Marshal.dump(options))
        opts.reject! { |k| k == 'table' } if options[:table]
        if job_flow_ids = opts.delete(:job_flow_ids)
          opts.merge!('JobFlowIds' => job_flow_ids)
        end
        if job_flow_status = opts.delete(:job_flow_status)
          opts.merge!('JobFlowStates' => job_flow_status)
        end
        if options[:table]
          puts 'For detailed information, dont pass --table option'
          job_flows = @conn.describe_job_flows(opts).body['JobFlows']
          table_data = Array.new
          unless job_flows.empty?
            job_flows.each do |job_flow|
              table_data << {
                              :job_flow_id => job_flow['JobFlowId'],
                              :name => job_flow['Name'],
                              :instance_count => job_flow['Instances']['InstanceCount'],
                              :master_dns => job_flow['Instances']['MasterPublicDnsName'],
                              :ec2_key_name => job_flow['Instances']['Ec2KeyName'],
                              :state => job_flow['ExecutionStatusDetail']['State']
                            }
            end
          end
          Formatador.display_table(table_data, [:job_flow_id, :name, :state, :instance_count, :master_dns, :ec2_key_name])
        else
          puts 'For less information, pass --table option'
          puts @conn.describe_job_flows(opts).body['JobFlows'].to_yaml
        end
      end

      def create_job_flow(options)
        # => BOOTSTRAP ACTIONS
        boot_strap_actions = []
        if options[:bootstrap_actions]
          options[:bootstrap_actions].each do |step|
            boot_strap_actions << parse_boot_strap_actions(step)
          end
        end

        # => STEPS
        steps = []
        if options[:custom_jar_steps]
          options[:custom_jar_steps].each do |step|
            steps << parse_custom_jar(step)
          end
        end
        if options[:hive_interactive]
          steps << hive_install(options[:hadoop_version])
        end
        if options[:pig_interactive]
          steps << pig_install
        end
        if options[:hive_steps]
          steps << hive_install(options[:hadoop_version]) unless options[:hive_interactive]
          options[:hive_steps].each do |step|
            steps << parse_hive_steps(step)
          end
        end
        if options[:pig_steps]
          steps << pig_install unless options[:pig_interactive]
          options[:pig_steps].each do |step|
            steps << parse_pig_steps(step, options[:hadoop_version])
          end
        end
        if options[:streaming_steps]
          options[:streaming_steps].each do |step|
            steps << parse_streaming_steps(step)
          end
        end
        if options[:hbase_install]
          boot_strap_actions << hbase_install_boot_strap
          steps << hbase_install_steps
          #validate hadoop version and instance size
          abort "Invalid hadoop version #{options[:hadoop_version]}, supported Hadoop Versions for HBase are: #{Awscli::EMR::HBASE_SUPPORTED_HADOOP.join(',')}" unless Awscli::EMR::HBASE_SUPPORTED_HADOOP.include?(options[:hadoop_version])
          options[:instance_groups] && parse_instance_groups(options[:instance_groups]).each do |group|
            unless is_valid_instance_type?(group['InstanceType'])
              abort "Instance type #{group['InstanceType']} is not compatible with HBase, instance size should be equal or greater than m1.large"
            end
          end
          if options[:master_instance_type]
            unless is_valid_instance_type?(options[:master_instance_type])
              abort "Instance type #{options[:master_instance_type]} is not compatible with HBase, instance size should be equal or greater than m1.large"
            end
          end
          if options[:slave_instance_type]
            unless is_valid_instance_type?(options[:slave_instance_type])
              abort "Instance type #{options[:slave_instance_type]} is not compatible with HBase, instance size should be equal or greater than m1.large"
            end
          end
          # => HBase backups
          if options[:hbase_backup_schedule]
            # Backup
            if options[:hbase_consistent_backup]
              steps << parse_hbase_backup(options[:hbase_backup_schedule], true)
            else
              steps << parse_hbase_backup(options[:hbase_backup_schedule])
            end
          elsif options[:hbase_backup_restore]
            # Restore
            steps << parse_hbase_restore(options[:hbase_backup_restore])
          end
        end

        # => INSTANCES
        instances = Hash.new
        instances['HadoopVersion'] = options[:hadoop_version]
        if options[:hive_interactive] or options[:pig_interactive] or options[:hbase_install]  #then job flow should not be terminated
          instances['KeepJobFlowAliveWhenNoSteps'] = true
        else
          instances['KeepJobFlowAliveWhenNoSteps'] = options[:alive]
        end
        instances['Ec2KeyName'] = options[:instance_ec2_key_name] if options[:instance_ec2_key_name]
        instances['InstanceCount'] = options[:instance_count] if options[:instance_count]
        instances['MasterInstanceType'] = options[:master_instance_type] if options[:master_instance_type]
        instances['SlaveInstanceType'] = options[:slave_instance_type] if options[:slave_instance_type]
        instances['TerminationProtected'] = options[:termination_protection] if options[:termination_protection]
        # => Instance Groups
        instances['InstanceGroups'] = parse_instance_groups(options[:instance_groups]) if options[:instance_groups]

        # => Build final request
        job_flow = Hash.new
        job_flow['AmiVersion'] = Awscli::EMR::HADOOP_AMI_MAPPING[options[:hadoop_version]]
        job_flow['LogUri'] = options[:log_uri] if options[:log_uri]
        job_flow['BootstrapActions'] = boot_strap_actions if options[:bootstrap_actions] or options[:hbase_install]
        job_flow['Instances'] = instances
        job_flow['Steps'] = steps
        if options[:alive] or options[:hive_interactive] or options[:pig_interactive] or options[:hbase_install]
          @conn.run_job_flow("#{options[:name]} (requires manual termination)", job_flow)
        else
          @conn.run_job_flow(options[:name], job_flow)
        end
        puts "Create JobFlow '#{options[:name]}' Successfully!"
      end

      def add_instance_group(options)
        opts = Marshal.load(Marshal.dump(options))
        opts.reject! { |key| key == 'job_flow_id' }
        opts.reject! { |key| key == 'region' }
        abort 'invalid job id' unless @conn.describe_job_flows.body['JobFlows'].map { |job| job['JobFlowId'] }.include?(options[:job_flow_id])
        abort 'invalid instance type' unless Awscli::Instances::INSTANCE_SIZES.include?(options[:instance_type])
        if instance_count = opts.delete(:instance_count)
          opts.merge!('InstanceCount' => instance_count)
        end
        if instance_type = opts.delete(:instance_type)
          opts.merge!('InstanceType' => instance_type)
        end
        if instance_role = opts.delete(:instance_role)
          opts.merge!('InstanceRole' => instance_role)
        end
        if name = opts.delete(:name)
          opts.merge!('Name' => name)
        end
        if bid_price = opts.delete(:bid_price)
          opts.merge!('BidPrice' => bid_price)
          opts.merge!('MarketType' => 'SPOT')
        else
          opts.merge!('MarketType' => 'ON_DEMAND')
        end
        (instance_groups ||= []) << opts
        @conn.add_instance_groups(options[:job_flow_id], 'InstanceGroups' => instance_groups)
        puts "Added instance group to job flow(with id): #{options[:job_flow_id]}"
      end

      def add_steps(job_flow_id, job_steps)
        validate_job_ids job_flow_id
        @conn.add_job_flow_steps(job_flow_id, 'Steps' => parse_custom_jar(job_steps))
        puts "Added step to job flow id: #{job_flow_id}"
      end

      def modify_instance_group(options)
        abort "Invalid instance group id: #{options[:instance_group_id]}" unless validate_instance_group_id?(options[:instance_group_id])
        @conn.modify_instance_groups(
            'InstanceGroups' => [
              'InstanceCount' => options[:instance_count],
              'InstanceGroupId' => options[:instance_group_id]
            ]
        )
      rescue Excon::Errors::BadRequest
        puts "[Error]: #{$!}"
      else
        puts "Modified instance group #{options[:instance_group_id]} size to #{options[:instance_count]}"
      end

      def set_termination_protection(job_flow_ids, terminate_protection)
        validate_job_ids job_flow_ids
        @conn.set_termination_protection(
            terminate_protection,
            {
                'JobFlowIds' => job_flow_ids
            }
        )
        terminate_protection ?
          puts("Termination protection flag added to job_flows: #{job_flow_ids.join(',')}") :
          puts("Termination protection flag removed from job_flows: #{job_flow_ids.join(',')}")
      end

      def add_instance_groups(job_flow_id, groups)
        validate_job_ids job_flow_id
        instance_groups = parse_instance_groups(groups)
        @conn.add_instance_groups(job_flow_id, 'InstanceGroups' => instance_groups)
      end

      def delete(job_ids)
        validate_job_ids job_ids
        @conn.terminate_job_flows('JobFlowIds' => job_ids)
        puts "Terminated Job Flows: #{job_ids.join(',')}"
      end

      private

      def validate_job_ids(job_ids)
        available_job_ids = @conn.describe_job_flows.body['JobFlows'].map { |job| job['JobFlowId'] }
        abort 'invalid job id\'s' unless available_job_ids.each_cons(job_ids.size).include? job_ids
      end

      def validate_instance_group_id?(group_id)
        @conn.describe_job_flows.body['JobFlows'].map { |j| j['Instances']['InstanceGroups'].map {|g| g['InstanceGroupId']} }.flatten.include?(group_id)
      end

      def is_valid_instance_type?(instance_type)
        ! Awscli::EMR::HBASE_INVALID_INSTANCES.member?(instance_type)
      end

      def parse_instance_groups(groups)
        #parse instance_groups => instance_count,instance_role(MASTER | CORE | TASK),instance_type,name,bid_price
        instance_groups = []
        groups.each do |group|
          instance_count, instance_role, instance_size, name, bid_price = ig.split(',')
          if instance_count.empty? or instance_role.empty? or instance_size.empty?
            abort 'instance_count, instance_role and instance_size are required'
          end
          abort "Invalid instance role: #{instance_role}" unless %w(MASTER CORE TASK).include?(instance_role.upcase)
          abort "Invalid instance type: #{instance_size}" unless Awscli::Instances::INSTANCE_SIZES.include?(instance_size)
          if bid_price
            instance_groups << {
                'BidPrice' => bid_price,
                'InstanceCount' => instance_count.to_i,
                'InstanceRole' => instance_role,
                'InstanceType' => instance_size,
                'MarketType' => 'SPOT',
                'Name' => name || "awscli-emr-#{instance_role}-group",
            }
          else
            instance_groups << {
                'InstanceCount' => instance_count.to_i,
                'InstanceRole' => instance_role,
                'InstanceType' => instance_size,
                'MarketType' => 'ON_DEMAND',
                'Name' => name || "awscli-emr-#{instance_role}-group",
            }
          end
        end
        instance_groups
      end

      def parse_boot_strap_actions(step)
        #parse => name,bootstrap_action_path,bootstrap_action_args
        name, path, *args = step.split(',')
        if name.empty? or path.empty?
          abort 'name and path are required'
        end
        boot_strap_actions = {
          'Name' => name,
          'ScriptBootstrapAction' => {
            'Args' => args || [],
            'Path' => path
          }
        }
        boot_strap_actions
      end

      def parse_custom_jar(steps)
        #parse jar_path(s3)*,name_of_step*,main_class,action_on_failure(TERMINATE_JOB_FLOW | CANCEL_AND_WAIT | CONTINUE),arg1=agr2=arg3,properties(k=v,k=v)
        abort "invalid step pattern, expecting 'jar_path(s3)*,name_of_step*,main_class,action_on_failure,arg1=agr2=arg3,prop_k1=prop_v1,prop_k2=prop_v2)'" unless step =~ /(.*),(.*),(.*),(.*),(.*),(.*),(.*)/
        jar, name, main_class, action_on_failure, extra_args, *job_conf = step.split(',')
        if jar.empty? or name.empty?
          abort 'jar and name are required for a step'
        end
        step_to_run = {
          'ActionOnFailure' => action_on_failure.empty? ? 'TERMINATE_JOB_FLOW' : action_on_failure,
          'Name' => name,
          'HadoopJarStep' => {
            'Jar' => jar,
            'Args' => extra_args.empty? ? [] : extra_args.split('='),
            'Properties' => []
          }
        }
        #steps['HadoopJarStep']['Args'] + extra_args.split('=') unless extra_args
        step_to_run['HadoopJarStep']['MainClass'] = main_class unless main_class.empty?
        unless job_conf.empty?
          job_conf.each do |kv_pair|
            properties = {}
            properties['Key'], properties['Value'] = kv_pair.split('=')
            step_to_run['HadoopJarStep']['Properties'] << properties
          end
        end
        step_to_run
      end

      def parse_hive_steps(step)
        #parse script_path(s3)*,input_path(s3),output_path(s3),'-d','args1','-d','args2','-d','arg3'
        path, input_path, output_path, *args = step.split(',')
        abort 'path to the hive script is required' if path.empty?
        hive_step = {
          'ActionOnFailure' => 'TERMINATE_JOB_FLOW',
          'Name' => 'awscli-emr-hive-step',
          'HadoopJarStep' => {
            "Jar" => 's3://us-west-1.elasticmapreduce/libs/script-runner/script-runner.jar',
            "Args" => [
              's3://us-west-1.elasticmapreduce/libs/hive/hive-script',
              '--base-path',
              's3://us-west-1.elasticmapreduce/libs/hive/',
              '--run-hive-script',
              '--args',
              '-f',
              path
            ]
          }
        }
        hive_step['HadoopJarStep']['Args'] << '-d' << "INPUT=#{input_path}" unless input_path.empty?
        hive_step['HadoopJarStep']['Args'] << '-d' << "OUTPUT=#{output_path}" unless output_path.empty?
        hive_step['HadoopJarStep']['Args'] += args unless args.empty?
        hive_step
      end

      def parse_pig_steps(step, hadoop_version)
        #parse script_path(s3)*,input_path(s3),output_path(s3),'-p','args1','-p','args2','-p','arg3'
        path, input_path, output_path, *args = step.split(',')
        abort 'path to the hive script is required' if path.empty?
        pig_step = {
          'ActionOnFailure' => 'TERMINATE_JOB_FLOW',
          'Name' => 'awscli-emr-pig-step',
          'HadoopJarStep' => {
            "Jar" => 's3://us-west-1.elasticmapreduce/libs/script-runner/script-runner.jar',
            "Args" => %w(s3://us-west-1.elasticmapreduce/libs/pig/pig-script --base-path s3://us-west-1.elasticmapreduce/libs/pig/ --run-pig-script --pig-versions latest --args)
          }
        }
        pig_step['HadoopJarStep']['Args'] << '-p' << "INPUT=#{input_path}" unless input_path.empty?
        pig_step['HadoopJarStep']['Args'] << '-p' << "OUTPUT=#{output_path}" unless output_path.empty?
        pig_step['HadoopJarStep']['Args'] += args unless args.empty?
        pig_step['HadoopJarStep']['Args'] << path
        pig_step
      end

      def parse_streaming_steps(step)
        #parse input*:output*:mapper*:reducer*:extra_arg1:extra_arg2
        input, output, mapper, reducer, *args = step.split(',')
        #input, output, mapper, reducer, args, *job_conf = step.split(',')
        if input.empty? or output.empty? or mapper.empty? or reducer.empty?
          abort 'input, output, mapper and reducer are required'
        end
        streaming_step = {
          'ActionOnFailure' => 'TERMINATE_JOB_FLOW',
          'Name' => 'awscli-emr-streaming-step',
          'HadoopJarStep' => {
            "Jar" => '/home/hadoop/contrib/streaming/hadoop-streaming.jar',
            "Args" => [
              '-input', input,
              '-output', output,
              '-mapper', mapper,
              '-reducer', reducer
            ]
          }
        }
        streaming_step['HadoopJarStep']['Args'] + args unless args.empty?
        #TODO: Add -jobconf params as k=v,k=v,k=v
        #streaming_step['HadoopJarStep']['Args'] << '-job_conf' + job_conf if job_conf.empty?
        streaming_step
      end

      def hive_install(hadoop_version)
        {
          'ActionOnFailure' => 'TERMINATE_JOB_FLOW',
          'Name' => 'awscli-emr-hive-setup',
          'HadoopJarStep' => {
              'Args' => ['s3://us-east-1.elasticmapreduce/libs/hive/hive-script',
                         '--base-path',
                         's3://us-east-1.elasticmapreduce/libs/hive/',
                         '--install-hive',
                         '--hive-versions',
                         Awscli::EMR::HADOOP_HIVE_COMPATIBILITY[hadoop_version]
                        ],
              'Jar' => 's3://us-east-1.elasticmapreduce/libs/script-runner/script-runner.jar'
          }
        }
      end

      def pig_install
        {
          'ActionOnFailure' => 'TERMINATE_JOB_FLOW',
          'Name' => 'awscli-emr-pig-setup',
          'HadoopJarStep' => {
              'Args' => %w(s3://us-east-1.elasticmapreduce/libs/pig/pig-script --base-path s3://us-east-1.elasticmapreduce/libs/pig/ --install-pig --pig-versions latest),
              'Jar' => 's3://us-east-1.elasticmapreduce/libs/script-runner/script-runner.jar'
          }
        }
      end

      def hbase_install_boot_strap
        {
          'Name' => 'awscli-emr-install-hbase',
          'ScriptBootstrapAction' => {
              'Args' => [],
              'Path' => 's3://us-west-1.elasticmapreduce/bootstrap-actions/setup-hbase'
          }
        }
      end

      def hbase_install_steps
        {
          'ActionOnFailure' => 'CANCEL_AND_WAIT',
          'Name' => 'awscli-emr-start-hbase',
          'HadoopJarStep' => {
              'Jar' => '/home/hadoop/lib/hbase-0.92.0.jar',
              'Args' => %w(emr.hbase.backup.Main --start-master)
          }
        }
      end

      def parse_hbase_backup(backup_step, consistent=false)
        #parse frequency*,frequency_unit*(Days|Hrs|Mins),path(s3)*,start_time*(now|iso-format)
        frequency, frequency_unit, path, start_time = backup_step.split(',')
        abort 'Invalid backup step pattern, expecting frequency,frequency_unit(days|hrs|mins),path(s3),start_time(now|iso-format)' unless backup_step =~ /(.*),(.*),(.*),(.*)/
        if frequency.empty? or frequency_unit.empty? or path.empty? or start_time.empty?
          abort 'frequency, frequency_unit, path, start_time are required to perform a backup'
        end
        abort "Invalid frequency unit : #{frequency_unit}" unless %w(days hrs mins).include?(frequency_unit)
        hbase_backup_step = {
            'Name' => 'awscli-emr-schedule-hbase-backup',
            'ActionOnFailure' => 'CANCEL_AND_WAIT',
            'HadoopJarStep' => {
                'Jar' => '/home/hadoop/lib/hbase-0.92.0.jar',
                'Args' => ['emr.hbase.backup.Main', '--backup-dir', path, '--set-scheduled-backup', true, '--full-backup-time-interval',
                           frequency, '--incremental-backup-time-unit', frequency_unit, '--start-time', start_time]
            }
        }
        hbase_backup_step['HadoopJarStep']['Args'] << '--consistent' if consistent
        hbase_backup_step
      end

      def parse_hbase_restore(restore_step)
        #parse path(s3)*,version
        path, version = restore_step.split(',')
        if path.empty?
          abort 'path is required'
        end
        hbase_restore_step = {
            'Name' => 'awscli-emr-restore-hbase-backup',
            'ActionOnFailure' => 'CANCEL_AND_WAIT',
            'HadoopJarStep' => {
                'Jar' => '/home/hadoop/lib/hbase-0.92.0.jar',
                'Args' => ['emr.hbase.backup.Main', '--restore', '--backup-dir', path]
            }
        }
        if defined?(version).nil?
          hbase_restore_step['HadoopJarStep']['Args'] << '--backup-version' << version unless version.empty?
        end
        hbase_restore_step
      end
    end
  end
end