#external dependencies
begin
  require 'thor'
  require 'thor/group'
  require 'fog'
  require 'highline/import'
  require 'yaml'
rescue LoadError
  puts 'Failed to load gems: fog, highline, thor'
  exit 1
end

module AwsCli
  # => require all interfaces for awscli/
  require 'awscli/version.rb' #to get version
  require 'awscli/errors'

  # => first require cli so all subcommands can register
  require 'awscli/cli'
  # => register all subcommands
    #EC2
  require 'awscli/cli/ec2'
  require 'awscli/cli/ec2/instances'
  require 'awscli/cli/ec2/ami'
  require 'awscli/cli/ec2/ebs'
  require 'awscli/cli/ec2/eip'
  require 'awscli/cli/ec2/keypairs'
  require 'awscli/cli/ec2/monitoring'
  require 'awscli/cli/ec2/placement'
  require 'awscli/cli/ec2/reservedinstmng'
  require 'awscli/cli/ec2/secgroups'
  require 'awscli/cli/ec2/spot'
  require 'awscli/cli/ec2/tags'
  require 'awscli/cli/ec2/vmmng'
  require 'awscli/cli/ec2/vpc'
  require 'awscli/cli/ec2/vpc/network_acls'
  require 'awscli/cli/ec2/vpc/net_interfaces'
  require 'awscli/cli/ec2/vpc/internet_gateways'
  require 'awscli/cli/ec2/vpc/dhcp'
  require 'awscli/cli/ec2/vpc/subnet'
  require 'awscli/cli/ec2/vpc/route_tables'
    #S3
  require 'awscli/cli/s3'
  require 'awscli/cli/s3/files'
  require 'awscli/cli/s3/directories'
    #AS
  require 'awscli/cli/as'
  require 'awscli/cli/as/activities'
  require 'awscli/cli/as/configurations'
  require 'awscli/cli/as/groups'
  require 'awscli/cli/as/instances'
  require 'awscli/cli/as/policies'
    #IAM
  require 'awscli/cli/iam'
  require 'awscli/cli/iam/user'
  require 'awscli/cli/iam/group'
  require 'awscli/cli/iam/policies'
  require 'awscli/cli/iam/roles'
  require 'awscli/cli/iam/profiles'
    #EMR
  require 'awscli/cli/emr'
    #Dynamo
  require 'awscli/cli/dynamo'
  require 'awscli/cli/dynamo/table'
  require 'awscli/cli/dynamo/item'
end