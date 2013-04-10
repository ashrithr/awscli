module AwsCli
  module CLI
    module DYNAMO
      require 'awscli/cli/dynamo'
      class Item < Thor

        desc 'put [OPTIONS]', 'creates a new item, or replaces an old item with new item'
        long_desc <<-DESC
          Usage:

          `awscli dynamo item put -t <table_name> -i <pk_col_name>:<type>:<value> <col_name>:<type>:<value> -a <expected_attr_name>:<type>:<value> -e <true|false> -r <return_values>`

          Examples:

          Put an element into a table:

          `awscli dynamo item put -t test_table -i Id:N:1 UserName:S:test_user`

          Put an element into a table using conditional put: (The Expected parameter using combination of -a and -e allows you to provide an attribute name, and whether or not Amazon DynamoDB
          should check to see if the attribute value already exists; or if the attribute value exists and has a particular value before changing it)

          The following option combination replaces the item if the "Color" attribute doesn't already exist for that item:
          `-a Color -e false`

          The following option combination checks to see if the attribute with name "Color" has an existing value of "Yellow" before replacing the item
          `-a Color:S:Yellow -e true`

          By default, if you use the Expected parameter and provide a Value, Amazon DynamoDB assumes the attribute exists and has a current value
          to be replaced. So you don't have to specify {-e true}, because it is implied. You can shorten the request to:
          `-a Color:S:Yellow`

          `awscli dynamo item put -t test -i Id:N:1 UserName:S:test_user -a UserName:S:test -e true -r ALL_OLD`
        DESC
        method_option :table_name, :aliases => '-t', :required => true, :desc => 'name of the table to contain the item'
        method_option :item, :aliases => '-i', :type => :array, :required => true, :desc => 'item to insert (must include primary key as well). Format => attribute_name:type(N|NS|S|SS|B|BS):value'
        method_option :expected_attr, :aliases => '-e', :desc => 'data to check against for conditional put. Format => attribute_name:type:value'
        method_option :expected_exists, :aliases => '-x', :desc => 'set as false to only allow update if attribute does not exist. Valid values: true|false'
        method_option :return_values, :aliases => '-v', :default => 'NONE', :desc => 'data to return(use this parameter if you want to get the attribute name-value pairs before they were updated). Valid values in (ALL_NEW|ALL_OLD|NONE|UPDATED_NEW|UPDATED_OLD)'
        def put
          if options[:expected_exists]
            abort '--expected-exists only accepts true or false' unless %w(true false).include?(options[:expected_exists])
          end
          create_dynamo_object
          @ddb.put options
        end

        desc 'get', 'returns a set of Attributes for an item that matches the primary key'
        method_option :table_name, :aliases => '-t', :required => true, :desc => ' name of the table containing the requested item'
        method_option :hash_key, :aliases => '-k', :required => true, :desc => 'primary key values that define the item. Format => attr_type:attr_value'
        method_option :range_key, :aliases => '-r', :desc => 'optional info for range key. Format => attr_type:attr_value'
        method_option :attrs_to_get, :aliases => '-g', :type => :array, :desc => 'Array of Attribute names. If attribute names are not specified then all attributes will be returned'
        method_option :consistent_read, :aliases => '-c', :type => :boolean, :desc => 'If set then a consistent read is issued, otherwise eventually consistent is used'
        def get
          create_dynamo_object
          @ddb.get options
        end

        desc 'update', 'edits an existing items attributes'
        long_desc <<-DESC
          Update DynamoDB item, cannot update the primary key attributes using UpdateItem.
          Instead, delete the item and use put to create a new item with new attributes
        DESC
        method_option :table_name, :aliases => '-t', :required => true, :desc => 'name of the table containing the item to update'
        method_option :hash_key, :aliases => '-k', :required => true, :desc => 'primary key that defines the item. Format => attr_type:attr_value'
        method_option :range_key, :aliases => '-r', :desc => 'optional info for range key. Format => attr_type:attr_value'
        method_option :attr_updates, :aliases => '-u', :type =>:array, :required => true, :desc => 'array of attribute name to the new value for the update. Format: attribute_name:type:value'
        method_option :attr_updates_action, :aliases => '-a', :default => 'PUT', :desc => 'specifies how to perform the update. Possible values: (PUT|ADD|DELETE)'
        method_option :expected_attr, :aliases => '-e', :desc => 'designates an attribute for a conditional update. Format => attribute_name:type:value'
        method_option :expected_exists, :aliases => '-x', :desc => 'set as false to only allow update if attribute does not exist. Valid values: true|false'
        method_option :return_values, :aliases => '-v', :default => 'NONE', :desc => 'data to return(use this parameter if you want to get the attribute name-value pairs before they were updated). Valid values in (ALL_NEW|ALL_OLD|NONE|UPDATED_NEW|UPDATED_OLD)'
        def update
          if options[:expected_exists]
            abort '--expected-exists only accepts true or false' unless %w(true false).include?(options[:expected_exists])
          end
          create_dynamo_object
          @ddb.update options
        end

        desc 'delete', 'deletes a single item in a table by primary key'
        def delete

        end

        desc 'query', 'gets the values of one or more items and their attributes by primary key'
        def query

        end

        desc 'scan', 'returns one or more items and its attributes by performing a full scan of a table'
        def scan

        end

        desc 'batch_get', ' returns the attributes for multiple items from multiple tables using their primary keys'
        def batch_get

        end

        desc 'batch_write', 'enables you to put or delete several items across multiple tables in a single API call'
        def batch_write

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