#!/usr/bin/ruby
# coding: utf-8
self_file =
  if File.symlink?(__FILE__)
    require 'pathname'
    Pathname.new(__FILE__).realpath
  else
    __FILE__
  end
$:.unshift(File.dirname(self_file) + "/../lib")

require 'iceberg'
require 'net/https'
require 'json'
require 'fileutils'

class MultiReader

  def initialize
    @readers = []
    @cur = 0
  end

  def add(reader)
    @readers << reader
  end

  def read(size = nil)
    rv = ''
    loop do
      reader = @readers[@cur]
      break unless reader
      s = reader.read(size)
      if s
        rv += s
        if size
          size -= s.size
          break if size <= 0
        end
      else
        @cur += 1
      end
    end
    rv.size > 0 ? rv : nil
  end

end

class FileHub

  def initialize(uri)
    @uri = URI.parse(uri)
  end

  def gethttp
    http = Net::HTTP.new(@uri.host, @uri.port)
    if @uri.port == 443
      http.use_ssl = true
      #http.ca_file = 'cert.pem' # TODO
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.verify_depth = 5
    end
    http
  end

  def recentfiles
    req = Net::HTTP::Get.new('/api/v1/recentfiles')
    gethttp.start do |http|
      res = http.request(req)
      body = res.body
      JSON.parse(body)
    end
  end

  def download(encdigest, file)
    begin
      req = Net::HTTP::Get.new("/api/v1/download/#{encdigest}")
      gethttp.start do |http|
        http.request(req) do |res|
          res.read_body do |chunk|
            file.write(chunk)
          end
        end
      end
      # TODO check sha1sum
    rescue
      file.rm
    end
  end

  def uploadraw(file)
    gethttp.start do |http|
      encdigest = file.name
      req = Net::HTTP::Post.new('/api/v1/uploadraw')
      boundary = (0...50).map { (65 + rand(26)).chr }.join
      req.set_content_type("multipart/form-data; boundary=#{boundary}")
      body1 = StringIO.new(<<EOF)
--#{boundary}\r
Content-Disposition: form-data; name="file"; filename="#{encdigest}"\r
Content-Type: application/octet-stream\r
Content-Transfer-Encoding: binary\r
\r
EOF
      body3 = StringIO.new(<<EOF)
--#{boundary}--\r
\r

EOF
      mr = MultiReader.new
      mr.add(body1)
      mr.add(file)
      mr.add(body3)
      req.body_stream = mr
      req.content_length = body1.size + file.size + body3.size
      res = http.request(req)
      body = res.body
      JSON.parse(body)
    end
  end

end

b = Iceberg::Storage.new
hub = FileHub.new('https://box.sighash.info') # TODO
json = hub.recentfiles()
recentfiles = json['recentfiles']
recentfiles.each do |encdigest|
  file = b.getobject(encdigest)
  next if file.size
  puts "download: #{encdigest}"
  hub.download(encdigest, file)
end
dir = b.dir
dir.each do |filename|
  next unless filename.size == 40
  unless recentfiles.index(filename)
    puts "upload: #{filename}"
    # TODO check sha1sum before upload
    file = b.getobject(filename)
    json = hub.uploadraw(file)
  end
end
