# coding: utf-8

class Iceberg

  class Storage

    def initialize
    end

    def getobject(name)
      FileObject.new(name)
    end

    def dir
      Dir.new(SETTING['local']['download'])
    end

  end

  class FileObject

    def initialize(name)
      download = SETTING['local']['download']
      @name = name
      @path = File.join(download, name)
      @size = File.exist?(@path) ? File.size(@path) : nil
    end

    attr_reader :size, :name

    def write(data)
      @fd = File.open(@path, 'wb') unless @fd
      @fd.write(data)
    end

    def read(size = nil)
      @fd = File.open(@path, 'rb') unless @fd
      @fd.read(size)
    end

    def close
      return unless @fd
      @fd.close
      @fd = nil
    end

    def rm
      FileUtils.rm_f(@path)
    end

  end

end
