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
require 'net/http'
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

  def recentfiles
    Net::HTTP.start(@uri.host, @uri.port) do |http|
      req = Net::HTTP::Get.new('/api/v1/recentfiles')
      res = http.request(req)
      body = res.body
      JSON.parse(body)
    end
  end

  def download(encdigest, path)
    begin
      File.open(path, 'wb') do |fd|
        Net::HTTP.start(@uri.host, @uri.port) do |http|
          req = Net::HTTP::Get.new("/api/v1/download/#{encdigest}")
          http.request(req) do |res|
            res.read_body do |chunk|
              fd.write(chunk)
            end
          end
        end
      end
    rescue
      FileUtils.rm_f(path)
    end
  end

  def uploadraw(path)
    Net::HTTP.start(@uri.host, @uri.port) do |http|
      encdigest = File.basename(path)
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
      body2 = File.open(path, 'rb')
      body3 = StringIO.new(<<EOF)
--#{boundary}--\r
\r

EOF
      mr = MultiReader.new
      mr.add(body1)
      mr.add(body2)
      mr.add(body3)
      req.body_stream = mr
      req.content_length = body1.size + File.size(path) + body3.size
      res = http.request(req)
      body = res.body
      JSON.parse(body)
    end
  end

end

download = SETTING['local']['download']
hub = FileHub.new('http://box.sighash.info') # TODO
json = hub.recentfiles()
recentfiles = json['recentfiles']
recentfiles.each do |encdigest|
  file = File.join(download, encdigest)
  next if File.exist?(file)
  puts "download: #{encdigest}"
  hub.download(encdigest, file)
end
dir = Dir.new(download)
dir.each do |file|
  next unless file.size == 40
  unless recentfiles.index(file)
    puts "upload: #{file}"
    json = hub.uploadraw(File.join(download, file))
  end
end