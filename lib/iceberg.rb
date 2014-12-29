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

  def self.upload(path, tripkey, filesize, filemax)
    download = SETTING['local']['download']
    FileUtils.mkdir download unless File.exist?(download)
    tripkey = nil if tripkey.empty?
    raise 'size over' if File.new(path).size > filesize
    alldata = File.open(path, 'rb'){|fd| fd.read}
    digest = Digest::SHA1.hexdigest(alldata)
    cipher = OpenSSL::Cipher::Cipher.new(@@algorithm).encrypt
    cipher.key = digest
    encdata = cipher.update(alldata) + cipher.final
    encdigest = Digest::SHA1.hexdigest(encdata)
    dest = File.join(download, encdigest)
    unless File.exist?(dest)
      File.open(dest, 'wb'){|fd| fd.write(encdata)}
      n = @@redis.lpush(IBDB_RECENT, encdigest)
      tripcodelist = @@redis.smembers(IBDB_TRIPCODE_SET) || []
      while n.size > filemax
        n = @@redis.llen(IBDB_RECENT)
        dropdigest = @@redis.rpop(IBDB_RECENT)
        dropfile = File.join(download, dropdigest)
        dropsize = File.size(dropfile) / (1024 * 1024) # MiB
        dropsize = 1 if dropsize <= 0
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
          FileUtils.rm_f(dropfile)
          break
        end
        @@redis.lpush(IBDB_RECENT, dropdigest)
      end
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
      :digest => digest,
      :encdigest => encdigest,
      :tripcode => tripcode,
    }
  end

end
