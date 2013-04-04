module Awscli
  module Instances
    INSTANCE_SIZES = %w(t1.micro m1.small m1.medium m1.large m1.xlarge m3.xlarge m3.2xlarge m2.xlarge
                            m2.2xlarge m2.4xlarge c1.medium c1.xlarge hs1.8xlarge)
    INSTANCE_TYPES = %w(on-demand spot)
    REGIONS = %w(eu-west-1 sa-east-1 us-east-1 ap-northeast-1 us-west-2 us-west-1 ap-southeast-1 ap-southeast-2)
  end
  module EMR
    VALID_JOB_FLOW_STATUS = %w(RUNNING WAITING SHUTTING_DOWN STARTING)
    HADOOP_HIVE_COMPATIBILITY = {
      '1.0.3' => '0.8.1.6',
      '0.20.205' => '0.8.1.2',
      '0.20' => '0.7.1',
      '0.18' => '0.7.1'
    }
    HADOOP_AMI_MAPPING = {
      '1.0.3' => '2.3',
      '0.20.205' => '2.0',
      '0.20' => '1.0',
      '0.18' => '1.0'
    }
    HBASE_SUPPORTED_HADOOP_VERSIONS = %w(0.20.205 1.0.3)
    HBASE_INVALID_INSTANCES = %w(m1.small c1.medium)
  end
end