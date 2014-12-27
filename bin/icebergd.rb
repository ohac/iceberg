#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
self_file =
  if File.symlink?(__FILE__)
    require 'pathname'
    Pathname.new(__FILE__).realpath
  else
    __FILE__
  end
$:.unshift(File.dirname(self_file) + "/../lib")

require 'iceberg'
require 'haml'
require 'sinatra'
require 'nkf'
require 'fileutils'

ICEBERG_HOME = File.dirname(__FILE__) + '/../'
set :public_folder, ICEBERG_HOME + 'public'
set :views, ICEBERG_HOME + 'views'

enable :sessions

helpers do

  include Rack::Utils; alias_method :h, :escape_html
  def partial(template, options = {})
    options = options.merge({:layout => false})
    template = "_#{template.to_s}".to_sym
    haml(template, options)
  end

end

CONTENT_TYPES = {
    :html => 'text/html',
    :css => 'text/css',
    :js => 'application/javascript',
    :txt => 'text/plain',
    }

before do
  request_uri = case request.env['REQUEST_URI']
    when /\.css$/ ; :css
    when /\.js$/ ; :js
    when /\.txt$/ ; :txt
    else :html
  end
  content_type CONTENT_TYPES[request_uri], :charset => 'utf-8'
  response.headers['Cache-Control'] = 'no-cache'
end

@@redis = Redis.new
@@algorithm = 'AES-256-CBC'

get '/' do
  recentfiles = @@redis.lrange(IBDB_RECENT, 0, 3) # TODO
  haml :index, :locals => { :recentfiles => recentfiles }
end

get '/upload' do
  haml :upload, :locals => { :foo => nil }
end

post '/upload' do
  download = SETTING['local']['download']
  FileUtils.mkdir download unless File.exist?(download)
  f = params[:file]
  redirect '/upload' if f.nil? # TODO error
  path = f[:tempfile].path
  origname = f[:filename]
  origname = NKF.nkf("-w", origname) # TODO i18n
  origname = origname.tr(" ", "_")
  name = File.basename(origname)
  redirect '/upload' if File.new(path).size > 2 * 1024 * 1024
  alldata = File.open(path, 'rb'){|fd| fd.read}
  digest = Digest::SHA1.hexdigest(alldata)

  cipher = OpenSSL::Cipher::Cipher.new(@@algorithm).encrypt
  cipher.key = digest
p digest
  encdata = cipher.update(alldata) + cipher.final
  encdigest = Digest::SHA1.hexdigest(encdata)

  dest = File.join(download, encdigest)
  redirect '/upload' if File.exist?(dest) # TODO error
  File.open(dest, 'wb'){|fd| fd.write(encdata)}
  n = @@redis.lpush(IBDB_RECENT, encdigest)
  if n.size > 3 # TODO
    @@redis.rpop(IBDB_RECENT)
  end
  redirect '/'
end

get '/download/:name' do
  content_type 'application/octet-stream'
  name = params[:name]
  download = SETTING['local']['download']
  digest = params[:digest]
  if digest
    cipher = OpenSSL::Cipher::Cipher.new(@@algorithm).decrypt
    cipher.key = digest
  end

  file = File.join(download, name)
  stream do |out|
    File.open(file, 'rb') do |fd|
      loop do
        data = fd.read(32 * 1024)
        break unless data
        data = cipher.update(data) if cipher
        out << data
        sleep 0.1
      end
      out << cipher.final if cipher
    end
  end
end
