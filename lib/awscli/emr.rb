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
                              :ec2_key_name => job_flow['Instances']['Ec2KeyName']
                            }
            end
          end
          Formatador.display_table(table_data, [:job_flow_id, :name, :instance_count, :master_dns, :ec2_key_name])
        else
          puts 'For less information, pass --table option'
          puts @conn.describe_job_flows(opts).body['JobFlows'].to_yaml
        end
      end

      def create_job_flow(options)

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

      def delete job_ids
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
    end
  end
end