module AwsCli
  module CLI
    module DYNAMO
      require 'awscli/cli/dynamo'
      class Table < Thor

        desc 'list', 'list available tables'
        method_option :limit, :aliases => '-l', :type => :numeric, :desc => 'A number of maximum table names to return.'
        #method_option :exclusive_start_table_name, :aliases => '-e', :banner => 'NAME', :desc => 'The name of the table that starts the list'
        def list
          create_dynamo_object
          @ddb.list options
        end

        desc 'info', 'returns information about the table'
        method_option :name, :aliases => '-n', :required => true, :desc => 'name of the table to list information for'
        def info
          create_dynamo_object
          @ddb.describe options[:name]
        end

        desc 'create', 'create a new table'
        method_option :name, :aliases => '-n', :required => true, :desc => 'name of the table to create, name should be unique among your account'
        method_option :pk_name, :aliases => '-k', :required => true, :desc => 'primary key hash attribute name for the table'
        method_option :pk_type, :aliases => '-t', :required => true, :desc => 'type of the hash attribute, valid values in [N, NS, S, SS]. N-Number, NS-NumberSet, S-String, SS-StringSet'
        method_option :rk_name, :desc => 'range attribute name for the table (if specified will create a composite primary key)'
        method_option :rk_type, :desc => 'type of the range attribute, valid values in [N, NS, S, SS]'
        method_option :read_capacity, :aliases => '-r', :required => true, :type => :numeric, :desc => 'minimum number of consistent ReadCapacityUnits consumed per second for the specified table'
        method_option :write_capacity, :aliases => '-w', :required => true, :type => :numeric, :desc => 'minimum number of WriteCapacityUnits consumed per second for the specified table'
        def create
          #name should be > 3 and can contain a-z, A-Z, 0-9, _, .
          #type should be in N, NS, S, SS
          #read and write capacity in between 5..10000
          create_dynamo_object
          @ddb.create options
        end

        desc 'delete', 'deletes a table and all its items'
        method_option :name, :aliases => '-n', :required => true, :desc => 'name of the table to delete'
        def delete
          create_dynamo_object
          @ddb.delete options[:name]
        end

        desc 'update', 'updates existing dynamo db table provisioned throughput'
        method_option :name, :aliases => '-n', :required => true, :desc => 'name of the table to update'
        method_option :read_capacity, :aliases => '-r', :required => true, :type => :numeric, :desc => 'minimum number of consistent ReadCapacityUnits consumed per second for the specified table'
        method_option :write_capacity, :aliases => '-w', :required => true, :type => :numeric, :desc => 'minimum number of WriteCapacityUnits consumed per second for the specified table'
        def update
          create_dynamo_object
          @ddb.update options
        end

        private

        def create_dynamo_object
          puts 'Dynamo Establishing Connection...'
          $dynamo_conn =  if parent_options[:region]
                            Awscli::Connection.new.request_dynamo(parent_options[:region])
                          else
                            Awscli::Connection.new.request_dynamo
                          end
          puts 'Dynamo Establishing Connection... OK'
          @ddb = Awscli::DynamoDB::Table.new($dynamo_conn)
        end

        AwsCli::CLI::Dynamo.register AwsCli::CLI::DYNAMO::Table, :table, 'table [COMMAND]', 'Dynamo Table Management'

      end
    end
  end
end