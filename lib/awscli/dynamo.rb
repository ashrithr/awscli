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

      def query(options)
        opts = {}
        hash_key_type, hash_key_value = options[:hash_key_value].split(',')
        hash_key = { hash_key_type => hash_key_value }
        opts['AttributesToGet'] = options[:attrs_to_get] if options[:attrs_to_get]
        opts['Limit'] = options[:limit] if options[:limit]
        opts['Count'] = options[:count] if options[:count]
        opts['ConsistentRead'] = options[:consistent_read] if options[:consistent_read]
        if options[:range_key_filter]
          operator, attr_type, attr_value = options[:range_key_filter].split(',')
          opts['RangeKeyCondition'] = {
              'AttributeValueList' => [{ attr_type => attr_value }],
              'ComparisonOperator' => operator
          }
        end
        opts['ScanIndexForward'] = options[:scan_index_forward]
        if options[:start_key]
          opts['ExclusiveStartKey'] = {}
          hash_key_type, hash_key_value = options[:start_key].split(',')
          opts['ExclusiveStartKey']['HashKeyElement'] = { hash_key_type => hash_key_value }
          if options[:start_range_key]
            range_key_type, range_key_value = options[:start_range_key].split(',')
            opts['ExclusiveStartKey']['RangeKeyElement'] = { range_key_type => range_key_value }
          end
        end
        p opts
        data = @conn.query(options[:table_name], hash_key, opts)
      rescue Excon::Errors::BadRequest
        puts "[Error] Failed to perform scan on table. #{parse_excon_error_response($!)}"
      else
        total_items = data.data[:body]['Count']
        items = data.data[:body]['Items']
        if not options[:count]
          puts "Retrieved #{total_items} Items"
          Formatador.display_table(items)
        else
          puts "Items Count: #{total_items}"
        end
        puts "LastEvaluatedKey: #{data.data[:body]['LastEvaluatedKey']}" if data.data[:body]['LastEvaluatedKey']
      end

      def scan(options)
        opts = {}
        opts['AttributesToGet'] = options[:attrs_to_get] if options[:attrs_to_get]
        opts['Limit'] = options[:limit] if options[:limit]
        opts['ConsistentRead'] = options[:consistent_read] if options[:consistent_read]
        opts['Count'] = options[:count] if options[:count]
        if options[:scan_filter]
          #Operator(BETWEEN BEGINS_WITH EQ LE LT GE GT),Attr_Name,Attr_Type(N|S|B|NS|SS|BS),Attr_Value
          operator, attr_name, attr_type, attr_value = options[:scan_filter].split(',')
          #case operator
          #  when 'EQ', 'NE', 'LE', 'LT', 'GE', 'GT', 'CONTAINS', 'NOT_CONTAINS', 'BEGINS_WITH'
          #    #can contain only one AttributeValue element
          #  when 'BETWEEN'
          #    #contain two AttributeValue elements
          #  else
          #    #IN - can contain any number of AttributeValue elements
          #end
          opts['ScanFilter'] = {
              attr_name => {
                  'AttributeValueList' => [{ attr_type => attr_value }],
                  'ComparisonOperator' => operator
              }
          }
        end
        if options[:start_key]
          opts['ExclusiveStartKey'] = {}
          hash_key_type, hash_key_value = options[:start_key].split(',')
          opts['ExclusiveStartKey']['HashKeyElement'] = { hash_key_type => hash_key_value }
          if options[:start_range_key]
            range_key_type, range_key_value = options[:start_range_key].split(',')
            opts['ExclusiveStartKey']['RangeKeyElement'] = { range_key_type => range_key_value }
          end
        end
        data = @conn.scan(options[:table_name], opts)
      rescue Excon::Errors::BadRequest
        puts "[Error] Failed to perform scan on table. #{parse_excon_error_response($!)}"
      else
        total_items = data.data[:body]['Count']
        items = data.data[:body]['Items']
        if not options[:count]
          puts "Retrieved #{total_items} Items"
          Formatador.display_table(items)
        else
          puts "Items Count: #{total_items}"
        end
        puts "LastEvaluatedKey: #{data.data[:body]['LastEvaluatedKey']}" if data.data[:body]['LastEvaluatedKey']
      end

      def put(options)
        items = {}
        opts = {}
        options[:item].each do |item|
          abort "invalid item format: #{item}" unless item =~ /(.*):(N|S|NS|SS|B|BS):(.*)/
          attr_name, attr_type, attr_value = item.split(':', 3)
          case attr_type
            when 'N', 'S', 'B'
              items[attr_name] = { attr_type => attr_value }
            when 'NS', 'SS', 'BS'
              attr_value_arry = attr_value.split(';')
              abort 'Invalid attribute value format, attributes should be comma separated values' if attr_value_arry.empty?
              items[attr_name] = { attr_type => attr_value_arry }
            else
              abort 'Invalid attribute type'
          end
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

      def batch_get(options)
        request_items = {}
        map = options[:requests].zip(options[:attrs_to_get])
        map.each do |request_attrs_mapping|
          #tbl1_name*,KeySet1(hash_key_type*=hash_key_value*:range_key_type=range_key_value),KeySet2,KeySetN
          table_name, *keys = request_attrs_mapping.first.split(',')
          attrs = request_attrs_mapping.last.split(':') unless request_attrs_mapping.last.nil?
          request_items[table_name] = {}
          request_items[table_name]['Keys'] = []
          keys.each do |key|
            parsed_key = {}
            hash_key, range_key = key.split(':')
            hash_key_type, hash_key_value = hash_key.split('=')
            parsed_key['HashKeyElement'] = { hash_key_type => hash_key_value }
            unless range_key.nil?
              range_key_type, range_key_value = range_key.split('=')
              parsed_key['RangeKeyElement'] = { range_key_type => range_key_value }
            end
            request_items[table_name]['Keys'] << parsed_key
          end
          request_items[table_name]['AttributesToGet'] = attrs unless attrs.nil?
        end
        puts @conn.batch_get_item(request_items).data[:body]['Responses'].to_yaml
      rescue Excon::Errors::BadRequest
        puts "[Error] Failed to get item from table. #{parse_excon_error_response($!)}"
      end

      def batch_write(options)
        request_items = {}
        #request_items['RequestItems'] = {}
        options[:put_requests] and options[:put_requests].each do |request|
          #table_name,col_name1:col_type1:col_value1,col_name2:col_type2:col_value2 ..
          table_name, *cols = request.split(/,(?=(?:[^']|'[^']*')*$)/)
          request_items[table_name] ||= []
          put_request = {}
          put_request['PutRequest'] = {}
          put_request['PutRequest']['Item'] = {}
          cols.each do |col|
            col_name, col_type, col_value = col.split(':', 3)
            case col_type
              when 'N', 'S', 'B'
                put_request['PutRequest']['Item'][col_name] = { col_type => col_value }
              when 'NS', 'SS', 'BS'
                col_value_arry = col_value.split(';')
                abort 'Invalid attribute value format, attributes should be comma separated values' if col_value_arry.empty?
                put_request['PutRequest']['Item'][col_name] = { col_type => col_value_arry }
              else
                abort "Invalid attribute type: #{col_type}"
            end
          end
          request_items[table_name] << put_request
        end
        options[:delete_requests] and options[:delete_requests].each do |request|
          #table_name,KeySet1(hash_key_type*=hash_key_value*:range_key_type=range_key_value),KeySet2,KeySetN
          table_name, *keys = request.split(',')
          request_items[table_name] ||= []
          delete_request = {}
          delete_request['DeleteRequest'] = {}
          delete_request['DeleteRequest']['Key'] = {}
          keys.each do |key_set|
            hash_key, range_key = key_set.split(':')
            hash_key_type, hash_key_value = hash_key.split('=')
            delete_request['DeleteRequest']['Key']['HashKeyElement'] = { hash_key_type => hash_key_value }
            if range_key
              range_key_type, range_key_value = range_key.split('=')
              delete_request['DeleteRequest']['Key']['RangeKeyElement'] = { range_key_type => range_key_value }
            end
          end
          request_items[table_name] << delete_request
        end
        @conn.batch_write_item(request_items)
      rescue Excon::Errors::BadRequest
        puts "[Error] Failed to batch put/delete item to/from table. #{parse_excon_error_response($!)}"
      else
        puts 'Batch Put/Delete Succeeded'
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

      def delete(options)
        key = {}
        opts = {}
        #Build and validate key
        abort 'Invalid --hash-key format' unless options[:hash_key] =~ /(N|S|NS|SS|B|BS):(.*)/
        hash_key_type, hash_key_name = options[:hash_key].split(':')
        key['HashKeyElement'] = { hash_key_type => hash_key_name }
        if options[:range_key]
          abort 'Invalid --range-key format' unless options[:hash_key] =~ /(N|S|NS|SS|B|BS):(.*)/
          range_key_type, range_key_name = options[:range_key].split(':')
          key['RangeKeyElement'] = { range_key_type => range_key_name }
        end
        if options[:expected_attr] #-e
          expected_attr_name, expected_attr_type, expected_attr_value = options[:expected_attr].split(':')
          if expected_attr_name and expected_attr_type and expected_attr_value
            if options[:expected_exists] and options[:expected_exists] == 'true' #-e Id:S:001 -x true
              opts['Expected'] = { expected_attr_name => { 'Value' => { expected_attr_type => expected_attr_value }, 'Exists' => options[:expected_exists] } }
            else #-e Id:S:001
              opts['Expected'] = { expected_attr_name => { 'Value' => { expected_attr_type => expected_attr_value } } }
            end
          elsif expected_attr_name and not expected_attr_type and not expected_attr_value
            if options[:expected_exists] and options[:expected_exists] == 'false' #-e Id -x false
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
        @conn.delete_item(options[:table_name], key, opts)
      rescue Excon::Errors::BadRequest
        puts "[Error] Failed to delete item. #{parse_excon_error_response($!)}"
      else
        puts 'Item delete succeeded.'
      end

      private

      def parse_excon_error_response(response)
        response.response.data[:body].match(/message.*|Message.*/)[0].gsub(/[^A-Za-z0-9: ]/, '')
      end
    end
  end
end