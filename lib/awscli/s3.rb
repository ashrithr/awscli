module Awscli
  module S3
    require 'thread'

    class Files
      def initialize connection, options = {}
        @@conn = connection
      end

      def list dir_name
        dir = @@conn.directories.get(dir_name)
        abort "cannot find bucket: #{dir_name}" unless dir
        puts "LastModified \t SIZE \t Object"
        dir.files.each do |file|
          puts "#{file.last_modified} \t #{file.content_length} \t #{file.key}"
        end
      end

      def upload_file dir_name, file_path
        dir = @@conn.directories.get(dir_name)
        abort "cannot find bucket: #{dir_name}" unless dir
        file = File.expand_path(file_path)
        abort "Invalid file path: #{file_path}" unless File.exist?(file)
        file_name = File.basename(file)
        dir.files.create(
            :key => file_name,
            :body => File.open(file),
            :public => true
          )
        puts "Uploaded file: #{file_name} to bucket: #{dir_name}"
      end

      def download_file dir_name, file_name, path
        dir = @@conn.directories.get(dir_name)
        abort "cannot find bucket: #{dir_name}" unless dir
        local_path = File.expand_path(path)
        abort "Invalid file path: #{path}" unless File.exist?(local_path)
        remote_file = dir.files.get(file_name)
        abort "cannot find file: #{file_name}" unless remote_file
        File.open("#{local_path}/#{remote_file.key}", 'w') do |f|
          f.write(remote_file.body)
        end
        puts "Downloaded file: #{remote_file.key} to path: #{local_path}"
      end

      def delete_file dir_name, file_name
        dir = @@conn.directories.get(dir_name)
        abort "cannot find bucket: #{dir_name}" unless dir
        remote_file = dir.files.get(file_name)
        abort "cannot find file: #{file_name}" unless remote_file
        remote_file.destroy
        puts "Deleted file: #{file_name}"
      end

      def copy_file source_dir, source_file, dest_dir, dest_file
        @@conn.directories.get(source_dir).files.get(source_file).copy(dest_dir, dest_file)
      end

      def get_public_url dir_name, file_name
        url = @@conn.directories.get(dir_name).files.get(file_name).public_url
        puts "public url for the file: #{file_name} is #{url}"
      end
    end

    class Directories
      def initialize connection, options = {}
        @@conn = connection
      end

      def list
        @@conn.directories.table
      end

      def create options
        dir = @@conn.directories.create(options)
        puts "Create bucket: #{dir.key}"
      end

      def delete dir_name
        dir = @@conn.directories.get(dir_name)
        abort "Cannot find bucket #{dir_name}" unless dir
        #check if the dir is empty or not
        abort "Bucket is not empty, use rec_delete to force delete bucket" if dir.files.length != 0
        dir.destroy
        puts "Deleted Bucket: #{dir_name}"
      end

      def delete_rec dir_name
        #Forked from https://gist.github.com/bdunagan/1383301
        data_queue = Queue.new
        semaphore = Mutex.new
        threads = Array.new
        total_listed = 0
        total_deleted = 0
        thread_count = 20 #num_of_threads to perform deletion
        dir = @@conn.directories.get(dir_name)
        abort "Cannot find bucket #{dir_name}" unless dir
        if dir.files.length != 0
          if agree("Are you sure want to delete all the objects in the bucket ?  ", true)
            puts
            puts "==Deleting all the files in '#{dir_name}'=="
            #fetch files in the bucket
            threads << Thread.new do
              Thread.current[:name] = "get files"
              puts "...started thread '#{Thread.current[:name]}'...\n"
              # Get all the files from this bucket. Fog handles pagination internally
              dir.files.all.each do |file|
                data_queue.enq(file) #add the file into the queue
                total_listed += 1
              end
              # Add a final EOF message to signal the deletion threads to stop.
              thread_count.times {data_queue.enq(:EOF)}
            end
            # Delete all the files in the queue until EOF with N threads.
            thread_count.times do |count|
              threads << Thread.new(count) do |number|
                Thread.current[:name] = "delete files(#{number})"
                puts "...started thread '#{Thread.current[:name]}'...\n"
                # Dequeue until EOF.
                file = nil
                while file != :EOF
                  # Dequeue the latest file and delete it. (Will block until it gets a new file.)
                  file = data_queue.deq
                  file.destroy if file != :EOF
                  # Increment the global synchronized counter.
                  semaphore.synchronize {total_deleted += 1}
                  puts "Deleted #{total_deleted} out of #{total_listed}\n" if (rand(100) == 1)
                end
              end
            end
            # Wait for the threads to finish.
            threads.each do |t|
              begin
                t.join
              rescue RuntimeError => e
                puts "Failure on thread #{t[:name]}: #{e.message}"
              end
            end
            #finally delete the bucket it self
            dir.destroy
            puts "Deleted bucket: #{dir_name} and all its contents"
          end
        else
          #empty bucket
          dir.destroy
          puts "Deleted bucket: #{dir_name}"
        end
      end

      def get_acl dir_name
        dir = @@conn.directories.get(dir_name)
        abort "Cannot find bucket #{dir_name}" unless dir
        puts dir.acl
      end

      def set_acl dir_name, acl
        dir = @@conn.directories.get(dir_name)
        abort "Cannot find bucket #{dir_name}" unless dir
        dir.acl = acl
        puts "Acl has been changed to #{acl}"
      end

      def get_logging_status dir_name
        puts @@conn.get_bucket_logging(dir_name).body['BucketLoggingStatus']
      end

      def set_logging_status dir_name, logging_status = {}
        @@conn.put_bucket_logging dir_name, logging_status
      end
    end

  end
end