module AwsCli
  #This it the main cli runner class
  #All class_methods should be defined here except for Thor::Groups
  class Cli < ::Thor

    default_task :help_banner   #if no option is passed call help_banner task
    # class_option :config, :banner => "PATH", :type => :string,
    #              :desc => 'Configuration file, accepts ENV $AWSCLI_CONFIG_FILE',
    #              :default => ENV['AWSCLI_CONFIG_FILE'] || "~/.awscli.yml"

    desc 'help', 'help banner'
    def help_banner
      puts <<-HELP.gsub(/^ {8}/, '')
        Amazon Web Services Command Line Interface, Version - #{Awscli::VERSION}

      HELP
      help  #call help
    end

  end
end