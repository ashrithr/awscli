module Awscli
  module DynamoDB
    class Table
      def initialize(connection)
        @conn = connection
      end

      def list(options)
        opts = {}
        table_data = []
        opts['Limit'] = options[:limit] if options[:limit]
        @conn.list_tables(opts).body['TableNames'].each do |table|
          table_data << { :table => table }
        end
        if table_data.empty?
          puts 'No tables found'
        else
          Formatador.display_table(table_data)
        end
      end

      def create(options)
        key_schema, provisioned_throughput = {}, {}
        abort 'Invalid key type' unless %w(N NS S SS).include?(options[:pk_type])
        key_schema['HashKeyElement'] = {
          'AttributeName' => options[:pk_name],
          'AttributeType' => options[:pk_type]
        }
        if options[:rk_name]
          abort '--rk_type is required if --rk-name is passed' unless options[:rk_name]
          abort 'Invalid key type' unless %w(N NS S SS).include?(options[:rk_type])
          key_schema['RangeKeyElement'] = {
            'AttributeName' => options[:rk_name],
            'AttributeType' => options[:rk_type]
          }
        end
        provisioned_throughput['ReadCapacityUnits'] = options[:read_capacity]
        provisioned_throughput['WriteCapacityUnits'] = options[:write_capacity]
        @conn.create_table(options[:name], key_schema, provisioned_throughput)
      rescue Excon::Errors::BadRequest
        err_msg = $!.response.data[:body].match(/message.*/)[0].gsub(/[^A-Za-z0-9: ]/, '')
        puts "[Error] Failed to create table. #{err_msg}"
      else
        puts "Create table #{options[:name]} successfully."
      end

      def describe(table_name)
        puts @conn.describe_table(table_name).body.to_yaml
      rescue Excon::Errors::BadRequest
        puts 'Table not found'
      end

      def delete(table_name)
        @conn.delete_table(table_name)
      rescue Excon::Errors::BadRequest
        err_msg = $!.response.data[:body].match(/message.*/)[0].gsub(/[^A-Za-z0-9: ]/, '')
        puts "[Error] Failed to delete table. #{err_msg}"
      else
        puts "Delete table #{table_name} successfully."
      end

      def update(options)
        provisioned_throughput = {}
        provisioned_throughput['ReadCapacityUnits'] = options[:read_capacity]
        provisioned_throughput['WriteCapacityUnits'] = options[:write_capacity]
        @conn.update_table(options[:name], provisioned_throughput)
      rescue Excon::Errors::BadRequest
        err_msg = $!.response.data[:body].match(/message.*/)[0].gsub(/[^A-Za-z0-9: ]/, '')
        puts "[Error] Failed to update table. #{err_msg}"
      else
        puts "Table #{options[:name]} provisioned capacity updated successfully."
      end
    end

    class Items
      def initialize(connection)
        @conn = connection
      end

      def query
        #query
      end

      def scan
        #scan
      end

      def put
        #put_item
      end

      def get
        #get_item
      end

      def batch_get
        #batch_get_item
      end

      def batch_write
        #batch_write_item
      end

      def update
        #update_item
      end

      def delete
        #delete_item
      end
    end
  end
end