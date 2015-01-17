# coding: utf-8
require 'aws-sdk'

class Iceberg

  class Storage

    def initialize
      bucket = SETTING['local']['s3bucket']
      if bucket
        s3 = AWS::S3.new
        @bucket = s3.buckets[bucket]
      end
    end

    def getobject(name)
      if @bucket
        @bucket.objects['iceberg/' + name]
      else
        FileObject.new(name)
      end
    end

    def dir
      if @use_s3
      else
        Dir.new(SETTING['local']['download'])
      end
    end

  end

  class FileObject

    def initialize(key)
      download = SETTING['local']['download']
      @key = key
      @path = File.join(download, key)
      @content_length = File.exist?(@path) ? File.size(@path) : nil
    end

    attr_reader :content_length, :key

    def exists?
      @content_length != nil
    end

    # TODO S3 bin/icebergsync.rb
    def write(data)
      @fd = File.open(@path, 'wb') unless @fd
      @fd.write(data)
    end

    # TODO S3 bin/icebergsync.rb
    def read(size = nil)
      if block_given?
        close
        File.open(@path, 'rb') do |fd|
          loop do
            data = fd.read(32 * 1024) # TODO
            break unless data
            yield(data)
          end
        end
      else
        @fd = File.open(@path, 'rb') unless @fd
        @fd.read(size)
      end
    end

    def close
      return unless @fd
      @fd.close
      @fd = nil
    end

    def delete
      FileUtils.rm_f(@path)
    end

  end

end
