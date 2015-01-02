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
    Net::HTTP.start(@host, @port) do |http|
      token = gettoken(http)
      encdigest = 'ffff' # TODO
      req = Net::HTTP::Post.new('/api/v1/uploadraw/' + encdigest)
      boundary = 'myboundary' # TODO
      data = 'foobar' # TODO
      req.set_content_type("multipart/form-data; boundary=#{boundary}")
      req.body = <<EOF
--#{boundary}\r
Content-Disposition: form-data; name="#{encdigest}"\r
Content-Type: application/octet-stream\r
Content-Transfer-Encoding: binary\r
\r
#{data}\r
--#{boundary}--\r
EOF
      res = http.request(req)
      body = res.body
      JSON.parse(body)
    end
  end

end

download = SETTING['local']['download']
hub = FileHub.new('http://box.sighash.info') # TODO
json = hub.recentfiles()
json['recentfiles'].each do |encdigest|
  file = File.join(download, encdigest)
  next if File.exist?(file)
  puts "download: #{encdigest}"
  hub.download(encdigest, file)
end
