module AwsCli
  module CLI
    module AS
      require 'awscli/cli/as'
      class Activities < Thor

        desc "list", "list activities in auto scaling api as a yaml dump"
        method_option :group_name, :aliases => "-g", :banner => "NAME", :desc => "optionally pass in group name to narrow down results"
        def list
          create_as_object
          @as.list options
        end

        private

        def create_as_object
          puts "AS Establishing Connetion..."
          $as_conn =  Awscli::Connection.new.request_as
          puts "AS Establishing Connetion... OK"
          @as = Awscli::As::Activities.new($as_conn)
        end

        AwsCli::CLI::As.register AwsCli::CLI::AS::Activities, :activities, 'activities [COMMAND]', 'Auto Scaling Activities Management'

      end
    end
  end
end