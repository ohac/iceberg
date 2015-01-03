# coding: utf-8
require 'rubygems'
require 'fileutils'
require 'redis'
require 'yaml'
require 'openssl'

HOME_DIR = ENV['HOME']
SETTING_DIR = File.join(HOME_DIR, '.iceberg')
SETTING_FILE = File.join(SETTING_DIR, 'settings.yaml')
unless File.exist?(SETTING_DIR)
  FileUtils.mkdir SETTING_DIR
end
unless File.exist?(SETTING_FILE)
  open(SETTING_FILE, 'w') do |fd|
    setting = {
      'local' => {
        'download' => File.join(SETTING_DIR, 'download'),
        'filemax' => 200,
        'maxfilesize' => 20 * 1024 * 1024, # 20 MiB
        'demourl' => '/show/3f636ca05f41c4a6dfd5f8cbc7a9dc0125b9a9b7?' +
            'digest=cafcc2df4c3998ba5ab94b5262ef3369502488f7&' +
            'filename=jBRA8.webm' # Big Buck Bunny
      },
    }
    fd.puts(YAML.dump(setting))
  end
end

SETTING = YAML.load(File.read(SETTING_FILE))

IBDB_RECENT = 'iceberg:recent'
IBDB_TRIPCODE = 'iceberg:tripcode:'
IBDB_TRIPCODE_SET = 'iceberg:tripcode:set'
IBDB_TRIPCODE_FUND = 'iceberg:tripcode:fund:'

class Iceberg

  def self.uploadimpl1
    download = SETTING['local']['download']
    FileUtils.mkdir download unless File.exist?(download)
    download
  end

  def self.uploadimpl2(filemax, encdigest)
    n = @@redis.lpush(IBDB_RECENT, encdigest)
    tripcodelist = @@redis.smembers(IBDB_TRIPCODE_SET) || []
    while n.size > filemax
      n = @@redis.llen(IBDB_RECENT)
      dropdigest = @@redis.rpop(IBDB_RECENT)
      dropfile = File.join(download, dropdigest)
      dropsize = File.size(dropfile) / (1024 * 1024) # MiB
      dropsize = 1 if dropsize <= 0 # TODO handle under 1 MiB
      found = false
      tripcodelist.each do |tripcode|
        next unless @@redis.sismember(IBDB_TRIPCODE + tripcode, dropdigest)
        v = @@redis.get(IBDB_TRIPCODE_FUND + tripcode)
        if v.to_i > 0
          @@redis.decrby(IBDB_TRIPCODE_FUND + tripcode, dropsize)
          found = true
          break
        end
      end
      unless found
        # TODO do not remove small files (for now)
        FileUtils.rm_f(dropfile) if File.size(dropfile) > 64 * 1024 # 64 KiB
        break
      end
      @@redis.lpush(IBDB_RECENT, dropdigest)
    end
  end

  def self.upload(path, tripkey, filesize, filemax, text = nil)
    download = uploadimpl1()
    tripkey = nil if tripkey.empty?
    if path
      raise 'size over' if File.new(path).size > filesize
      alldata = File.open(path, 'rb'){|fd| fd.read}
    else
      raise 'size over' if text.size > filesize # TODO convert to binary size
      alldata = text
    end
    digest = Digest::SHA1.digest(alldata)
    hexdigest = digest.unpack('H*')[0]
    cipher = OpenSSL::Cipher::Cipher.new(@@algorithm).encrypt
    cipher.key = digest[0, 16]
    cipher.iv = digest[4, 16]
    encdata = cipher.update(alldata) + cipher.final
    encdigest = Digest::SHA1.hexdigest(encdata)
    dest = File.join(download, encdigest)
    unless File.exist?(dest)
      File.open(dest, 'wb'){|fd| fd.write(encdata)}
      uploadimpl2(filemax, encdigest)
    end
    if tripkey
      tripcode = Base64.encode64(Digest::SHA1.digest(tripkey))[0, 12]
      tripcode = tripcode.tr('/', '.')
      @@redis.sadd(IBDB_TRIPCODE_SET, tripcode)
      @@redis.sadd(IBDB_TRIPCODE + tripcode, encdigest)
      # TODO test (initial bonus)
      v = @@redis.get(IBDB_TRIPCODE_FUND + tripcode)
      if v
        @@redis.incrby(IBDB_TRIPCODE_FUND + tripcode, 1)
      else
        @@redis.set(IBDB_TRIPCODE_FUND + tripcode, 2)
      end
    end
    {
      :digest => hexdigest,
      :encdigest => encdigest,
      :tripcode => tripcode,
    }
  end

  def self.uploadraw(path, filesize, filemax)
    download = uploadimpl1()
    raise 'size over' if File.new(path).size > filesize
    encdata = File.open(path, 'rb'){|fd| fd.read}
    encdigest = Digest::SHA1.hexdigest(encdata)
    # TODO check filename
    dest = File.join(download, encdigest)
    unless File.exist?(dest)
      # TODO move!
      File.open(dest, 'wb'){|fd| fd.write(encdata)}
      uploadimpl2(filemax, encdigest)
    end
    {
    }
  end

  def self.download(name, filename, hexdigest)
    ctype, disp = case filename
      when /\.jpg$/ ; ['image/jpeg', 'inline']
      when /\.png$/ ; ['image/png', 'inline']
      when /\.gif$/ ; ['image/gif', 'inline']
      when /\.mp3$/ ; ['audio/mpeg', 'inline']
      when /\.ogg$/ ; ['audio/ogg', 'inline']
      when /\.flac$/ ; ['audio/flac', 'inline']
      when /\.webm$/ ; ['video/webm', 'inline']
      when /\.txt$/ ; ['text/plain', 'inline']
      else ['application/octet-stream', 'attachment']
    end
    download = SETTING['local']['download']
    if hexdigest
      digest = [hexdigest].pack('H*')
      cipher = OpenSSL::Cipher::Cipher.new(@@algorithm).decrypt
      cipher.key = digest[0, 16]
      cipher.iv = digest[4, 16]
    end
    file = File.join(download, name)
    [ctype, disp, file, cipher]
  end

end
