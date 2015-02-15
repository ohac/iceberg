#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'haml'
require 'sinatra/base'
require 'nkf'
require 'fileutils'
require 'base64'
require 'json'
require 'i18n'
require 'i18n/backend/fallbacks'

module Iceberg

  class WebApp < Sinatra::Base

    ICEBERG_HOME = File.dirname(__FILE__) + '/../../'
    set :protection, :except => :frame_options
    set :public_folder, ICEBERG_HOME + 'public'
    set :views, ICEBERG_HOME + 'views'

    FORBIDDEN_CHARS = " #<>:\\/*?\"|&',;`"

    enable :sessions
    enable :logging

    configure do
      I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
      locales = Dir[File.join(ICEBERG_HOME, 'locales', '*.yml')]
      I18n.load_path = locales
      I18n.backend.load_translations
    end

    helpers do

      include Rack::Utils; alias_method :h, :escape_html
      def partial(template, options = {})
        options = options.merge({:layout => false})
        template = "_#{template.to_s}".to_sym
        haml(template, options)
      end

      def t(text)
        I18n.t(text)
      end

    end

    CONTENT_TYPES = {
        :html => 'text/html',
        :css => 'text/css',
        :js => 'application/javascript',
        :txt => 'text/plain',
        }

    before do
      request_uri = case request.env['REQUEST_URI'].split('?')[0]
        when /\.css$/ ; :css
        when /\.js$/ ; :js
        when /\.txt$/ ; :txt
        else :html
      end
      content_type CONTENT_TYPES[request_uri], :charset => 'utf-8'
      response.headers['Cache-Control'] = 'no-cache'
      I18n.locale = session[:locale] || 'ja'
    end

    get '/' do
      locale = params[:locale]
      if locale
        I18n.locale = locale
        session[:locale] = locale
      end
      filemax = SETTING['local']['filemax']
      recentfiles = REDIS.lrange(IBDB_RECENT, 0, filemax)
      tripcodelist = REDIS.smembers(IBDB_TRIPCODE_SET)
      uploaded = session[:uploaded]
      session[:uploaded] = nil
      maxfilesize = SETTING['local']['maxfilesize']
      recentpeers = REDIS.lrange(IBDB_RECENT_PEERS, 0, 10).map do |peer|
        digest = Iceberg.ip2digest(peer)
        peerinfo = JSON.parse(REDIS.hget(IBDB_PEERS, digest) || '{}')
        [digest, peerinfo['download']]
      end
      haml :index, :locals => { :recentfiles => recentfiles,
          :uploaded => uploaded, :tripcodelist => tripcodelist,
          :filemax => filemax, :maxfilesize => maxfilesize,
          :recentpeers => recentpeers }
    end

    get '/api/v1/recentfiles' do
      filemax = SETTING['local']['filemax']
      recentfiles = REDIS.lrange(IBDB_RECENT, 0, filemax)
      rv = { :recentfiles => recentfiles, :filemax => filemax }
      rv.to_json + "\n"
    end

    get '/api/v1/tripcodelist' do
      tripcodelist = REDIS.smembers(IBDB_TRIPCODE_SET)
      rv = { :tripcodelist => tripcodelist }
      rv.to_json + "\n"
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
        origname = origname.tr(FORBIDDEN_CHARS, "_")
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

    post '/api/v1/uploadraw' do
      begin
        f = params[:file]
        raise if f.nil?
        path = f[:tempfile].path
        origname = f[:filename] # TODO check SHA-1
        filemax = SETTING['local']['filemax']
        maxfilesize = SETTING['local']['maxfilesize']
        rv = Iceberg.uploadraw(path, maxfilesize, filemax)
      rescue => x
        rv = { :error => x.to_s }
      end
      content_type CONTENT_TYPES[:js], :charset => 'utf-8'
      rv.to_json + "\n"
    end

    post '/uploadtext' do
      # TODO
      text = params[:text]
      title = params[:title]
      begin
        filemax = SETTING['local']['filemax']
        maxfilesize = SETTING['local']['maxfilesize']
        rv = Iceberg.upload(nil, params[:tripkey], maxfilesize, filemax, text)
        origname = "#{title}.txt"
        origname = origname.tr(FORBIDDEN_CHARS, "_")
        rv[:name] = origname
        session[:uploaded] = rv
      rescue => x
p x
      end
      redirect '/'
    end

    get '/show/:name' do
      name = params[:name]
      filename = params[:filename]
      hexdigest = params[:digest]
      b = Storage.new
      o = b.getobject(name)
      ex = o.exists?
      size = ex ? o.content_length : nil
      haml :show, :locals => {:name => name, :filename => filename,
          :hexdigest => hexdigest, :filesize => size,
          :exists => o.exists?}
    end

    post '/shorten' do
      name = params[:name]
      filename = params[:filename]
      hexdigest = params[:digest]
      seconds = params[:seconds]
      params = hexdigest ? "?digest=#{hexdigest}&filename=#{filename}" : ''
      url = "/show/#{name}#{params}"
      key = Iceberg.url2key(url, seconds)
      haml :shorten, :locals => {:key => key}
    end

    get '/s/:key' do
      key = params[:key]
      url = Iceberg.key2url(key)
      redirect url if url
      sleep 1 # TODO bruteforce attack
      raise
    end

    get '/container/:name' do
      name = params[:name]
      hexdigest = params[:digest]
      filename = params[:filename]
      haml :container, :locals => { :name => name, :hexdigest => hexdigest,
          :filename => filename }
    end

    ['/download/:name', '/api/v1/download/:name'].each do |path|
      get path do
        name = params[:name]
        name = name.split('.')[0] if name.index('.')
        filename = params[:filename]
        hexdigest = params[:digest]
        ctype, disp, file, cipher = Iceberg.download(name, filename, hexdigest)
        error 404 unless file.exists?
        if ctype == 'text/plain'
          content_type ctype, :charset => 'utf-8'
        else
          content_type ctype
        end
        if filename
          response.headers['Content-Disposition'] =
              "#{disp}; filename=\"#{filename}\""
        end
        range = request.env['HTTP_RANGE']
        skip = 0
        size = nil
        if range
          range = range.split('=')[1].split('-').map(&:to_i)
          size = range[1]
          if size
            skip = range[0]
            size = size + 1 - skip
            status 206
          end
        end
        if size && size < 4 * 1024 * 1024 # TODO under 4 MiB
          out = ''
          begin
            file.read do |data|
              data = cipher.update(data) if cipher
              out << data
            end
            if cipher
              data = cipher.final
              out << data
            end
          rescue => x
p x
          end
          Iceberg.recordip(request.ip)
          response.headers['Content-Range'] = "bytes #{range.join('-')}/#{out.size}"
          out[skip, size]
        else
          stream do |out|
            begin
              file.read do |data|
                data = cipher.update(data) if cipher
                if skip <= 0
                  if size
                    if size > 0
                      out << data[0, size]
                      size -= data.size
                    end
                  else
                    out << data
                  end
                else
                  if skip >= data.size
                    skip -= data.size
                  else
                    if size
                      out << data[skip, size]
                      size -= data.size - skip
                    else
                      out << data[(skip)..-1]
                    end
                    skip = 0
                  end
                end
                sleep 0.1 # TODO
              end
              if cipher
                data = cipher.final
                if skip <= 0
                  if size
                    if size > 0
                      out << data[0, size]
                    end
                  else
                    out << data
                  end
                else
                  if size
                    out << data[skip, size]
                  else
                    out << data[(skip)..-1]
                  end
                end
              end
            rescue => x
p x
            end
            Iceberg.recordip(request.ip)
          end
        end
      end
    end

    get '/tripcode/:tripcode' do
      tripcode = params[:tripcode]
      files = REDIS.smembers(IBDB_TRIPCODE + tripcode)
      fund = REDIS.get(IBDB_TRIPCODE_FUND + tripcode)
      haml :tripcode, :locals => { :tripcode => tripcode, :files => files,
          :fund => fund }
    end

  end

end
