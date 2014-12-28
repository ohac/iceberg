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
IBDB_TRIPCODE_LIST = 'iceberg:tripcode:list'
IBDB_TRIPCODE_FUND = 'iceberg:tripcode:fund:'
