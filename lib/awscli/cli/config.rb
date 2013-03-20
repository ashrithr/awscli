#####################################################################
#For normal Thor classes, each task must be registered individually #
#####################################################################
module AwsCli
  require 'awscli/cli'
  class Config < Thor

    method_option :dr, :type => :numeric, :desc => "repeat greeting X times", :default => 3
    desc "show_default", "show the default config"
    def show_default
      puts "default " * options.dr
    end
    # AwsCli::Cli.register AwsCli::Config, :show_default, "show_default", "print default"
    # AwsCli::Cli.tasks["show_default"].options = AwsCli::Config.tasks["show_default"].options

    method_option :cr, :type => :numeric, :desc => "repeat greeting X times", :default => 3
    desc "show_config", "show the config"
    def show_config
      puts "config " * options.cr
    end
    # AwsCli::Cli.register AwsCli::Config, :show_config, "show_config", "print config"
    # AwsCli::Cli.tasks["show_config"].options = AwsCli::Config.tasks["show_config"].options
    # => Register config as a sub command to Cli class
    AwsCli::Cli.register AwsCli::Config, :config, 'config [COMMAND]', 'Delegates a subcomamnd'
  end
end