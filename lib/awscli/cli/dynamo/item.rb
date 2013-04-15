module AwsCli
  module CLI
    module DYNAMO
      require 'awscli/cli/dynamo'
      class Item < Thor

        conditional_item = <<-eos
          Conditional Put/Delete/Update an Item:

          Put/Delete/Update an element into a table using conditional put/delete/update: (The Expected parameter using
          combination of -e and -x allows you to provide an attribute name, and whether or not Amazon DynamoDB
          should check to see if the attribute value already exists; or if the attribute value exists and has a
          particular value before changing it)

          The following option combination replaces/deletes/updates the item if the "Color" attribute doesn't already
          exist for that item:
          `-e Color -x false`

          The following option combination checks to see if the attribute with name "Color" has an existing value of
          "Yellow" before replacing/deleting/updating the item
          `-e Color:S:Yellow -x true`

          By default, if you use the Expected parameter and provide a Value, Amazon DynamoDB assumes the attribute
          exists and has a current value to be replaced. So you don't have to specify {-x true}, because it is implied.
          You can shorten the request to:
          `-e Color:S:Yellow`
        eos

        desc 'put [OPTIONS]', 'creates a new item, or replaces an old item with new item'
        long_desc <<-DESC
          Usage:

          `awscli dynamo item put -t <table_name> -i <pk_col_name>:<type>:<value> <col_name>:<type>:<value> -a <expected_attr_name>:<type>:<value> -e <true|false> -r <return_values>`

          Examples:

          Put an element into a table:

          `awscli dynamo item put -t test_table -i Id:N:1 UserName:S:test_user`

           #{conditional_item}

          `awscli dynamo item put -t test -i Id:N:1 UserName:S:test_user -a UserName:S:test -e true -r ALL_OLD`
        DESC
        method_option :table_name, :aliases => '-t', :desc => 'name of the table to contain the item'
        method_option :item, :aliases => '-i', :type => :array, :desc => 'item to insert (must include primary key as well). Format => attribute_name:type(N|NS|S|SS|B|BS):value'
        method_option :expected_attr, :aliases => '-e', :desc => 'data to check against for conditional put. Format => attribute_name:type:value'
        method_option :expected_exists, :aliases => '-x', :desc => 'set as false to only allow update if attribute does not exist. Valid values: true|false'
        method_option :return_values, :aliases => '-v', :default => 'NONE', :desc => 'data to return(use this parameter if you want to get the attribute name-value pairs before they were updated). Valid values in (ALL_NEW|ALL_OLD|NONE|UPDATED_NEW|UPDATED_OLD)'
        def put
          unless options[:table_name] and options[:item]
            abort 'required options --table-name, --item'
          end
          if options[:expected_exists]
            abort '--expected-exists only accepts true or false' unless %w(true false).include?(options[:expected_exists])
          end
          create_dynamo_object
          @ddb.put options
        end

        desc 'get [OPTIONS]', 'returns a set of Attributes for an item that matches the primary key'
        method_option :table_name, :aliases => '-t', :desc => ' name of the table containing the requested item'
        method_option :hash_key, :aliases => '-k', :desc => 'primary key values that define the item. Format => attr_type:attr_value'
        method_option :range_key, :aliases => '-r', :desc => 'optional info for range key. Format => attr_type:attr_value'
        method_option :attrs_to_get, :aliases => '-g', :type => :array, :desc => 'Array of Attribute names. If attribute names are not specified then all attributes will be returned'
        method_option :consistent_read, :aliases => '-c', :type => :boolean, :desc => 'If set then a consistent read is issued, otherwise eventually consistent is used'
        def get
          unless options[:table_name] and options[:hash_key]
            abort 'required options --table-name, --hash-key'
          end
          create_dynamo_object
          @ddb.get options
        end

        desc 'update [OPTIONS]', 'edits an existing items attributes'
        long_desc <<-DESC
          Update DynamoDB item, cannot update the primary key attributes using UpdateItem.
          Instead, delete the item and use put to create a new item with new attributes
        DESC
        method_option :table_name, :aliases => '-t', :desc => 'name of the table containing the item to update'
        method_option :hash_key, :aliases => '-k', :desc => 'primary key that defines the item. Format => attr_type:attr_value'
        method_option :range_key, :aliases => '-r', :desc => 'optional info for range key. Format => attr_type:attr_value'
        method_option :attr_updates, :aliases => '-u', :type =>:array, :desc => 'array of attribute name to the new value for the update. Format: attribute_name:type:value'
        method_option :attr_updates_action, :aliases => '-a', :default => 'PUT', :desc => 'specifies how to perform the update. Possible values: (PUT|ADD|DELETE)'
        method_option :expected_attr, :aliases => '-e', :desc => 'designates an attribute for a conditional update. Format => attribute_name:type:value'
        method_option :expected_exists, :aliases => '-x', :desc => 'set as false to only allow update if attribute does not exist. Valid values: true|false'
        method_option :return_values, :aliases => '-v', :default => 'NONE', :desc => 'data to return(use this parameter if you want to get the attribute name-value pairs before they were updated). Valid values in (ALL_NEW|ALL_OLD|NONE|UPDATED_NEW|UPDATED_OLD)'
        def update
          unless options[:table_name] and options[:hash_key] and options[:attr_updates]
            abort 'required options --table-name, --hash-kye, --attr-updates'
          end
          if options[:expected_exists]
            abort '--expected-exists only accepts true or false' unless %w(true false).include?(options[:expected_exists])
          end
          create_dynamo_object
          @ddb.update options
        end

        desc 'delete [OPTIONS]', 'deletes a single item in a table by primary key'
        long_desc <<-DESC
          Deletes a single item in a table by primary key. You can perform a conditional delete operation that deletes
          the item if it exists, or if it has an expected attribute value.

          If you specify DeleteItem without attributes or values, all the attributes for the item are deleted
        DESC
        method_option :table_name, :aliases => '-t', :desc => 'name of the table containing the item to delete'
        method_option :hash_key, :aliases => '-k', :desc => 'primary key that defines the item. Format => attr_type:attr_value'
        method_option :range_key, :aliases => '-r', :desc => 'optional info for range key. Format => attr_type:attr_value'
        method_option :expected_attr, :aliases => '-e', :desc => 'data to check against for conditional put. Format => attribute_name:type:value'
        method_option :expected_exists, :aliases => '-x', :desc => 'set as false to only allow update if attribute does not exist. Valid values: true|false'
        method_option :return_values, :aliases => '-v', :default => 'NONE', :desc => 'data to return(use this parameter if you want to get the attribute name-value pairs before they were updated). Valid values in (ALL_NEW|ALL_OLD|NONE|UPDATED_NEW|UPDATED_OLD)'
        def delete
          unless options[:table_name] and options[:hash_key]
            abort 'required options --table-name, --hash-key'
          end
          if options[:expected_exists]
            abort '--expected-exists only accepts true or false' unless %w(true false).include?(options[:expected_exists])
          end
          create_dynamo_object
          @ddb.delete options
        end

        desc 'query [OPTIONS]', 'returns one or more items and their attributes by primary key (only available for hash-and-range primary key tables)'
        method_option :table_name, :aliases => '-t', :desc => 'name of the table containing the requested items'
        method_option :attrs_to_get, :aliases => '-g', :type => :array, :desc => 'array of attribute names, if attribute names are not specified then all attributes will be returned'
        method_option :limit, :aliases => '-l', :type => :numeric, :desc => 'limit of total items to return'
        method_option :count, :aliases => '-c', :type => :boolean, :default => false, :desc => 'if true, returns only a count of such items rather than items themselves'
        method_option :hash_key_value, :aliases => '-v', :desc => 'attribute value of the hash component of the composite primary key. Format => HashKeyElementType,HashKeyElementValue'
        method_option :range_key_filter, :aliases => '-f', :desc => 'A container for the attribute values and comparison operators to use for the query. Format => Operator(BETWEEN BEGINS_WITH EQ LE LT GE GT),Attr_Type(N|S|B|NS|SS|BS),Attr_Value'
        method_option :scan_index_forward, :aliases => '-i', :default => 'true', :desc => 'Specifies ascending or descending traversal of the index, Possible Values: (true|false). Default: true'
        method_option :start_key, :aliases => '-s', :desc => 'Primary key of the item from which to continue an earlier scan. Format => HashKeyElementType,HashKeyElementValue'
        method_option :start_range_key, :aliases => '-k', :desc => 'Primary Range key of the item from which to continue an earlier scan. Format => RangeKeyElementType,RangeKeyElementValue'
        def query
          unless options[:table_name] and options[:hash_key_value]
            abort 'options --table-name and --hash-key-value are required'
          end
          abort 'invalid --hash-key-value format' unless options[:hash_key_value] =~ /^(.*?),(.*?)$/
          if options[:scan_index_forward]
            abort 'invalid option --scan-index-forward value' unless options[:scan_index_forward] =~ /true|false/
          end
          if options[:range_key_filter]
            abort 'invalid --range-key-filter format' unless options[:range_key_filter] =~ /^(BETWEEN|BEGINS_WITH|EQ|LE|LT|GE|GT),(N|S|B|NS|SS|BS),(.*?)$/
          end
          if options[:start_key]
            abort 'Invalid --start-key format' unless options[:start_key] =~ /^(.*?),(.*?)$/
          end
          if options[:start_range_key]
            abort 'Invalid --start-range-key format' unless options[:start_range_key] =~ /^(.*?),(.*?)$/
          end
          create_dynamo_object
          @ddb.query options
        end

        desc 'scan [OPTIONS]', 'returns one or more items and its attributes by performing a full scan of a table'
        long_desc <<-DESC

        DESC
        method_option :table_name, :aliases => '-t', :desc => 'name of the table containing the requested items'
        method_option :attrs_to_get, :aliases => '-g', :type => :array, :desc => 'array of attribute names, if attribute names are not specified then all attributes will be returned'
        method_option :limit, :aliases => '-l', :type => :numeric, :desc => 'limit of total items to return'
        method_option :count, :aliases => '-c', :type => :boolean, :default => false, :desc => 'if true, returns only a count of such items rather than items themselves'
        method_option :consistent_read, :type => :boolean, :default => false, :desc => 'whether to wait for consistency, defaults to false'
        method_option :scan_filter, :aliases => '-f', :desc => 'Evaluates the scan results and returns only the desired values. Format=> Operator(BETWEEN BEGINS_WITH EQ LE LT GE GT),Attr_Name,Attr_Type(N|S|B|NS|SS|BS),Attr_Value'
        method_option :start_key, :aliases => '-s', :desc => 'Primary key of the item from which to continue an earlier scan. Format => HashKeyElementType,HashKeyElementValue'
        method_option :start_range_key, :aliases => '-k', :desc => 'Primary Range key of the item from which to continue an earlier scan. Format => RangeKeyElementType,RangeKeyElementValue'
        def scan
          unless options[:table_name]
            abort 'option --table-name is required.'
          end
          if options[:scan_filter]
            abort 'Invalid --scan-filter format' unless options[:scan_filter] =~ /^(BETWEEN|BEGINS_WITH|EQ|LE|LT|GE|GT),(.*?),(N|S|B|NS|SS|BS),(.*?)$/
          end
          if options[:start_key]
            abort 'Invalid --start-key format' unless options[:start_key] =~ /^(.*?),(.*?)$/
          end
          if options[:start_range_key]
            abort 'Invalid --start-range-key format' unless options[:start_range_key] =~ /^(.*?),(.*?)$/
          end
          create_dynamo_object
          @ddb.scan options
        end

        desc 'batch_get [OPTIONS]', 'returns the attributes for multiple items from multiple tables using their primary keys'
        long_desc <<-DESC
        batch_get fetches items in parallel to minimize response latencies
        This operation has following limitations:
        The maximum number of items that can be retrieved for a single operation is 100. Also, the number of items.
        Retrieved is constrained by a 1 MB size limit.

        Usage Examples:

        The following example will get the data from two different tables: comp2 & comp1. From table comp2 get username and friends
        whose primary hash keys are Julie & Mingus and of type S(String). From table comp1 get username and status whose primary keys
        are Casey & Dave of type S(String) and also match data based on range key 1319509152 & 1319509155 respectively for users.

        `awscli dynamo item batch_get -r comp2,S=Julie,S=Mingus comp1,S=Casey:N=1319509152,S=Dave:N=1319509155 -g user:friends user:status`
        DESC
        method_option :requests, :aliases => '-r', :type => :array, :desc => 'A container of the table name and corresponding items to get by primary key. Format => tbl1_name*,KeySet1(hash_key_type*=hash_key_value*:range_key_type=range_key_value),KeySet2,KeySetN'
        method_option :attrs_to_get, :aliases => '-g', :type => :array, :desc => 'Attributes to get from each respective table. Format => tbl1_attr1:tbl1_attr2:tbl1_attr3 tbl2_attr1:tbl2_attr2:tbl2_attr3 ..'
        method_option :consistent_read, :aliases => '-c', :type => :boolean, :desc => 'If set then a consistent read is issued, otherwise eventually consistent is used'
        def batch_get
          unless options[:requests]
            abort 'option --requests is required'
          end
          options[:requests].each do |request|
            unless request =~ /^(.*?)(?:,((N|S|B|NS|SS|BS)=(.*?))(:(N|S|B|NS|SS|BS)=(.*?))*)+$/
              abort 'Invalid --request format, see `awscli dynamo item help batch_get` for usage examples'
            end
          end
          create_dynamo_object
          @ddb.batch_get options
        end

        desc 'batch_write [OPTIONS]', 'performs put or delete several items across multiple tables'
        long_desc <<-DESC
        `batch_write` enables you to put or delete several items across multiple tables in a single API call
        This operation has following limitations:
        Maximum operations in a single request: You can specify a total of up to 25 put or delete operations.
        Unlike the put and delete, batch_write does not allow you to specify conditions on individual write requests in the operation.

        Usage Examples:

        The following batch_write operation will put an item into User, Item tables and deletes item from User, Thread tables

        `bundle exec bin/awscli dynamo item batch_write --put-requests User,Id:S:003,UserName:S:user123,Password:S:secret123 Item,Id:S:'Amazon Dynamo DB#Thread 5',ReplyDateTime:S:'2012-04-03T11:04:47.034Z' --delete-requests User,S=003 Thread,S='Amazon DynamoDB#Thread 4':S='oops - accidental row'`
        DESC
        method_option :put_requests, :aliases => '-p', :type => :array, :desc => 'Format=> table_name,col_name1:col_type1:col_value1,col_name2:col_type2:col_value2 ..'
        method_option :delete_requests, :aliases => '-d', :type => :array, :desc => 'Format=> table_name,hash_key_type*=hash_key_value*:range_key_type=range_key_value ..'
        def batch_write
          unless options[:put_requests] or options[:delete_requests]
            abort 'option --put-requests or --delete-requests is required to perform batch_write'
          end
          options[:put_requests] and options[:put_requests].each do |put_request|
            unless put_request =~ /^(.*?)(?:,((.*?):(N|S|B|NS|SS|BS):(.*?))*)+$/
              abort 'Invalid --put-requests format, see `awscli dynamo item help batch_write` for usage examples'
            end
          end
          options[:delete_requests] and options[:delete_requests].each do |delete_request|
            unless delete_request =~ /^(.*?)(?:,((N|S|B|NS|SS|BS)=(.*?))(:(N|S|B|NS|SS|BS)=(.*?))*)+$/
              abort 'Invalid --delete-requests format, see `awscli dynamo item help batch_write` for usage examples'
            end
          end
          create_dynamo_object
          @ddb.batch_write options
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
          @ddb = Awscli::DynamoDB::Items.new($dynamo_conn)
        end

        AwsCli::CLI::Dynamo.register AwsCli::CLI::DYNAMO::Item, :item, 'item [COMMAND]', 'Dynamo DB Item(s) Management'

      end
    end
  end
end