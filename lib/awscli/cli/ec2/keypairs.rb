module AwsCli
  module CLI
    module EC2
      require 'awscli/cli/ec2'
      class KeyPairs < Thor

        desc "list", "List Key Pairs"
        def list
          puts "Listing Key Pairs"
          create_ec2_object
          @ec2.list_keypairs
        end

        desc "create", "Create Key Pair"
        method_option :name, :aliases => "-n", :required => true, :banner => "NAME", :type => :string, :desc => "Name of the key pair to create"
        method_option :fingerprint, :type => :string, :desc => "Fingerprint for the key(optional)"
        method_option :private_key, :type => :string, :desc => "Private Key for the key(optional)"
        def create
          create_ec2_object
          @ec2.create_keypair options
        end

        desc "delete", "Delete Key Pair"
        method_option :name, :aliases => "-n", :required => true, :banner => "NAME", :type => :string, :desc => "Name of the key pair to delete"
        def delete
          create_ec2_object
          @ec2.delete_keypair options[:name]
        end

        desc "fingerprint", "Describe Key Fingerprint"
        method_option :name, :aliases => "-n", :required => true, :banner => "NAME", :type => :string, :desc => "Name of the key pair to delete"
        def fingerprint
          create_ec2_object
          @ec2.fingerprint options[:name]
        end

        desc "import", "Imports an Key Pair"
        method_option :name, :aliases => "-n", :required => true, :banner => "NAME", :type => :string, :desc => "Name of the key pair to import"
        method_option :private_key_path, :aliases => "-p", :banner => "PATH", :type => :string, :desc => "Optionally pass private key path, by default tries to retrieve from user ~/.ssh dir"
        method_option :public_key_path, :aliases => "-k", :banner => "PATH", :type => :string, :desc => "Optionally pass public key path, by default tries to retrieve from user ~/.ssh dir"
        def import
          create_ec2_object
          @ec2.import_keypair options
        end

        private

        def create_ec2_object
          puts "ec2 Establishing Connetion..."
          $ec2_conn = if parent_options[:region]
                        Awscli::Connection.new.request_ec2(parent_options[:region])
                      else
                        Awscli::Connection.new.request_ec2
                      end
          puts "ec2 Establishing Connetion... OK"
          @ec2 = Awscli::EC2::KeyPairs.new($ec2_conn)
        end

        AwsCli::CLI::Ec2.register AwsCli::CLI::EC2::KeyPairs, :kp, 'kp [COMMAND]', 'EC2 Key Pair Management'

      end
    end
  end
end