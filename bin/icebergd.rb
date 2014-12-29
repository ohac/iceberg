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
require 'json'

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
  filemax = SETTING['local']['filemax']
  recentfiles = @@redis.lrange(IBDB_RECENT, 0, filemax)
  tripcodelist = @@redis.smembers(IBDB_TRIPCODE_SET)
  uploaded = session[:uploaded]
  session[:uploaded] = nil
  filemax = SETTING['local']['filemax']
  maxfilesize = SETTING['local']['maxfilesize']
  haml :index, :locals => { :recentfiles => recentfiles,
      :uploaded => uploaded, :tripcodelist => tripcodelist,
      :filemax => filemax, :maxfilesize => maxfilesize }
end

post '/upload' do
  f = params[:file]
  redirect '/' if f.nil? # TODO error
  path = f[:tempfile].path
  begin
    filemax = SETTING['local']['filemax']
    maxfilesize = SETTING['local']['maxfilesize']
    rv = Iceberg.upload(path, params[:tripkey], maxfilesize, filemax)
    origname = f[:filename]
    origname = File.basename(origname)
    origname = NKF.nkf("-w", origname) # TODO i18n
    origname = origname.tr(" ", "_") # TODO check other XSS
    rv[:name] = origname
    session[:uploaded] = rv
  rescue => x
p x
  end
  redirect '/'
end

post '/api/v1/upload' do
  begin
    f = params[:file]
    raise if f.nil?
    path = f[:tempfile].path
    filemax = SETTING['local']['filemax']
    maxfilesize = SETTING['local']['maxfilesize']
    rv = Iceberg.upload(path, params[:tripkey], maxfilesize, filemax)
  rescue => x
    rv = { :error => x.to_s }
  end
  content_type CONTENT_TYPES[:js], :charset => 'utf-8'
  rv.to_json + "\n"
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
