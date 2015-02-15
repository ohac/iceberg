# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ibg/version'

Gem::Specification.new do |spec|
  spec.name          = "ibg"
  spec.version       = Iceberg::VERSION
  spec.authors       = ["OHASHI Hideya"]
  spec.email         = ["ohachige@gmail.com"]
  spec.summary       = %q{Decenterized file storage}
  spec.description   = %q{Decenterized file storage}
  spec.homepage      = "https://box.sighash.info/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency 'sinatra'
  spec.add_dependency 'thin'
  spec.add_dependency 'haml'
  spec.add_dependency 'redis'
  spec.add_dependency 'aws-sdk'
  spec.add_dependency 'i18n'
end
