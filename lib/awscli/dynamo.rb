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
        puts "[Error] Failed to create table. #{parse_excon_error_response($!)}"
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
        puts "[Error] Failed to delete table. #{parse_excon_error_response($!)}"
      else
        puts "Delete table #{table_name} successfully."
      end

      def update(options)
        provisioned_throughput = {}
        provisioned_throughput['ReadCapacityUnits'] = options[:read_capacity]
        provisioned_throughput['WriteCapacityUnits'] = options[:write_capacity]
        @conn.update_table(options[:name], provisioned_throughput)
      rescue Excon::Errors::BadRequest
        puts "[Error] Failed to update table. #{parse_excon_error_response($!)}"
      else
        puts "Table #{options[:name]} provisioned capacity updated successfully."
      end

      private

      def parse_excon_error_response(response)
        response.data[:body].match(/message.*/)[0].gsub(/[^A-Za-z0-9: ]/, '')
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

      def put(options)
        items = {}
        opts = {}
        options[:item].each do |item|
          abort "invalid item format: #{item}" unless item =~ /(.*):(N|S|NS|SS|B|BS):(.*)/
          attr_name, attr_type, attr_value = item.split(':')
          items[attr_name] = { attr_type => attr_value }
        end
        if options[:expected_attr] #-a
          expected_attr_name, expected_attr_type, expected_attr_value = options[:expected_attr].split(':')
          if expected_attr_name and expected_attr_type and expected_attr_value
            if options[:expected_exists] and options[:expected_exists] == 'true' #-a Id:S:001 -e true
              opts['Expected'] = { expected_attr_name => { 'Value' => { expected_attr_type => expected_attr_value }, 'Exists' => options[:expected_exists] } }
            else #-a Id:S:001
              opts['Expected'] = { expected_attr_name => { 'Value' => { expected_attr_type => expected_attr_value } } }
            end
          elsif expected_attr_name and not expected_attr_type and not expected_attr_value
            if options[:expected_exists] and options[:expected_exists] == 'false' #-a Id -e false
              opts['Expected'] = { expected_attr_name => { 'Exists' => options[:expected_exists] } }
            else
              abort 'Invalid option combination, see help for usage examples'
            end
          else
            abort 'Invalid option combination, see help for usage examples'
          end
        end
        if options[:return_values]
          abort 'Invalid return type' unless %w(ALL_NEW ALL_OLD NONE UPDATED_NEW UPDATED_OLD).include?(options[:return_values])
          opts['ReturnValues'] = options[:return_values]
        end
        @conn.put_item(options[:table_name], items, opts)
      rescue Excon::Errors::BadRequest
        puts "[Error] Failed to put item into table. #{parse_excon_error_response($!)}"
      else
        puts 'Item put succeeded.'
      end

      def get(options)
        #get_item(table_name, key, options = {})
        opts = {}
        key = {}
        abort 'Invalid --hash-key format' unless options[:hash_key] =~ /(N|S|NS|SS|B|BS):(.*)/
        hash_key_type, hash_key_name = options[:hash_key].split(':')
        key['HashKeyElement'] = { hash_key_type => hash_key_name }
        if options[:range_key]
          abort 'Invalid --range-key format' unless options[:hash_key] =~ /(N|S|NS|SS|B|BS):(.*)/
          range_key_type, range_key_name = options[:range_key].split(':')
          key['RangeKeyElement'] = { range_key_type => range_key_name }
        end

        opts['AttributesToGet'] = options[:attrs_to_get] if options[:attrs_to_get]

        opts['ConsistentRead'] = true if options[:consistent_read]
        data = @conn.get_item(options[:table_name], key, opts)
      rescue Excon::Errors::BadRequest
        puts "[Error] Failed to get item from table. #{parse_excon_error_response($!)}"
      else
        #TODO: Pretty print this
        if not data.body['Item'].nil?
          puts 'Retrieved Items:'
          puts "ColumnName \t Type \t Value"
          data.body['Item'].each do |attr, pair|
            print "#{attr} \t"
            pair.map {|type,value|  print "#{type} \t #{value}"}
            puts
          end
        else
          puts 'No data retrieved'
        end
      end

      def batch_get
        #batch_get_item
      end

      def batch_write
        #batch_write_item
      end

      def update(options)
        opts = {}
        key = {}
        attribute_updates = {}
        #Build and validate key
        abort 'Invalid --hash-key format' unless options[:hash_key] =~ /(N|S|NS|SS|B|BS):(.*)/
        hash_key_type, hash_key_name = options[:hash_key].split(':')
        key['HashKeyElement'] = { hash_key_type => hash_key_name }
        if options[:range_key]
          abort 'Invalid --range-key format' unless options[:hash_key] =~ /(N|S|NS|SS|B|BS):(.*)/
          range_key_type, range_key_name = options[:range_key].split(':')
          key['RangeKeyElement'] = { range_key_type => range_key_name }
        end
        #Build and validate attribute_updates
        options[:attr_updates].each do |attr_update|
          abort "invalid item format: #{attr_update}" unless attr_update =~ /(.*):(N|S|NS|SS|B|BS):(.*)/
          attr_name, attr_type, attr_value = attr_update.split(':')
          attribute_updates[attr_name] = {
              'Value' => {attr_type => attr_value},
              'Action' => options[:attr_updates_action]
          }
        end
        #Build and validate options if any
        if options[:expected_attr] #-a
          expected_attr_name, expected_attr_type, expected_attr_value = options[:expected_attr].split(':')
          if expected_attr_name and expected_attr_type and expected_attr_value
            if options[:expected_exists] and options[:expected_exists] == 'true' #-a Id:S:001 -e true
              opts['Expected'] = { expected_attr_name => { 'Value' => { expected_attr_type => expected_attr_value }, 'Exists' => options[:expected_exists] } }
            else #-a Id:S:001
              opts['Expected'] = { expected_attr_name => { 'Value' => { expected_attr_type => expected_attr_value } } }
            end
          elsif expected_attr_name and not expected_attr_type and not expected_attr_value
            if options[:expected_exists] and options[:expected_exists] == 'false' #-a Id -e false
              opts['Expected'] = { expected_attr_name => { 'Exists' => options[:expected_exists] } }
            else
              abort 'Invalid option combination, see help for usage examples'
            end
          else
            abort 'Invalid option combination, see help for usage examples'
          end
        end
        if options[:return_values]
          abort 'Invalid return type' unless %w(ALL_NEW ALL_OLD NONE UPDATED_NEW UPDATED_OLD).include?(options[:return_values])
          opts['ReturnValues'] = options[:return_values]
        end
        @conn.update_item(options[:table_name], key, attribute_updates, opts)
      rescue Excon::Errors::BadRequest
        puts "[Error] Failed to update item. #{parse_excon_error_response($!)}"
      else
        puts 'Item update succeeded.'
      end

      def delete
        #delete_item
      end

      private

      def parse_excon_error_response(response)
        response.response.data[:body].match(/message.*/)[0].gsub(/[^A-Za-z0-9: ]/, '')
      end
    end
  end
end