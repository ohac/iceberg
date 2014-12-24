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

get '/' do
  haml :index, :locals => { :foo => nil }
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
  dest = File.join(download, name)
  redirect '/upload' if File.exist?(dest) # TODO error
  FileUtils.mv(path, dest)
  FileUtils.chmod(0644, dest)
  redirect '/'
end
