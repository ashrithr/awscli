#external dependencies
# begin
  require 'thor'
  require 'thor/group'
  require 'fog'
  require 'highline'
  require 'yaml'
# rescue LoadError
#   puts "Failed to load gems: fog, highline, thor"
#   exit 1
# end

module AwsCli
  # => require all interfaces for awscli/
  require 'awscli/version.rb' #to get version
  # => first require cli so all subcommands can register
  require 'awscli/cli'
  # => register all subcommands
  require 'awscli/cli/more'
  require 'awscli/cli/config'
end