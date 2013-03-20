#A thor group example -> main diff b/w thor class and thor group is that thor group invokes all tasks at once, it also
  #include some methods that allows invocations to be done at the class method, which are not available to thor tasks
#class_options defined for a thor group become method_options when used as subcommand
#Since AwsCli::Runner is already defined when this is evaluated, it automatically register itself as a subcommand to runner
module AwsCli
  module CLI
    # require 'awscli/cli' #to look up AwsCli::Cli.register
    class More < ::Thor::Group

      class_option :repeat, :type => :numeric, :desc => "repeat greeting X times", :default => 3

      desc "prints woot"
      def woot
        puts "woot! " * options.repeat
      end

      desc "prints toow"
      def toow
        puts "!toow" * options.repeat
      end

      #This line registers this group as a sub command of the runner
      AwsCli::Cli.register AwsCli::CLI::More,        #subclass to register
                           :more,               #subcommand name to use
                           "more",              #short usage for the subcommand
                           "Execute a multi step task"   #description for the subcommand
      #This line copies the class_options for this class to the method_options of the :more task
      AwsCli::Cli.tasks["more"].options = AwsCli::CLI::More.class_options
    end
  end
end