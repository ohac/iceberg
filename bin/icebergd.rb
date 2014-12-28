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
require 'base64'

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
  recentfiles = @@redis.lrange(IBDB_RECENT, 0, 200) # TODO
  tripcodelist = @@redis.smembers(IBDB_TRIPCODE_SET)
  uploaded = session[:uploaded]
  session[:uploaded] = nil
  haml :index, :locals => { :recentfiles => recentfiles,
      :uploaded => uploaded, :tripcodelist => tripcodelist }
end

post '/upload' do
  download = SETTING['local']['download']
  FileUtils.mkdir download unless File.exist?(download)
  f = params[:file]
  tripkey = params[:tripkey]
  tripkey = nil if tripkey.empty?
  redirect '/' if f.nil? # TODO error
  path = f[:tempfile].path
  origname = f[:filename]
  origname = NKF.nkf("-w", origname) # TODO i18n
  origname = origname.tr(" ", "_")
  name = File.basename(origname)
  redirect '/' if File.new(path).size > 20 * 1024 * 1024 # TODO
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
    while n.size > 200 do # TODO
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
  session[:uploaded] = {
    :name => name,
    :digest => digest,
    :encdigest => encdigest,
    :tripcode => tripcode,
  }
  redirect '/'
end

get '/download/:name' do
  name = params[:name]
  filename = params[:filename]
  ctype, disp = case filename
    when /\.jpg$/ ; ['image/jpeg', 'inline']
    when /\.png$/ ; ['image/png', 'inline']
    when /\.gif$/ ; ['image/gif', 'inline']
    when /\.mp3$/ ; ['audio/mpeg', 'inline']
    else ['application/octet-stream', 'attachment']
  end
  content_type ctype
  if filename
    response.headers['Content-Disposition'] =
        "#{disp}; filename=\"#{filename}\""
  end
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

get '/tripcode/:tripcode' do
  tripcode = params[:tripcode]
  files = @@redis.smembers(IBDB_TRIPCODE + tripcode)
  fund = @@redis.get(IBDB_TRIPCODE_FUND + tripcode)
  haml :tripcode, :locals => { :tripcode => tripcode, :files => files,
      :fund => fund }
end
