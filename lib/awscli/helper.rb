module Awscli
  module Instances
    INSTANCE_SIZES = %w(t1.micro m1.small m1.medium m1.large m1.xlarge m3.xlarge m3.2xlarge m2.xlarge
                            m2.2xlarge m2.4xlarge c1.medium c1.xlarge hs1.8xlarge)
    INSTANCE_TYPES = %w(on-demand spot)
    REGIONS = %w(eu-west-1 sa-east-1 us-east-1 ap-northeast-1 us-west-2 us-west-1 ap-southeast-1 ap-southeast-2)
  end
  module EMR
    VALID_JOB_FLOW_STATUS = %w(RUNNING WAITING SHUTTING_DOWN STARTING)
  end
end