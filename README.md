# Iceberg

[![Build Status](https://travis-ci.org/ohac/iceberg.svg?branch=master)](https://travis-ci.org/ohac/iceberg)

Demo site: https://box.sighash.info/

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ibg'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ibg

## Usage

    Server
    $ bundle exec rackup -s thin -p 4567
    or
    $ bundle exec bin/iceberg-web

    Client
    $ echo a > a
    $ sha1sum a
    3f786850e387550fdab836ed7e6dc881de23001b  a
    $ curl -F file=@a -F tripkey=a http://localhost:4567/api/v1/upload
    {"digest":"3f786850e387550fdab836ed7e6dc881de23001b","encdigest":"5618577aa4e6dc87931719ea26afbd7e886cb4e2","tripcode":"hvfkN.qlp.zh"}

    Server
    $ base64 ~/.iceberg/download/5618577aa4e6dc87931719ea26afbd7e886cb4e2 
    Zaf76KVeOWrs4UEWGqSReg==

    Client
    $ echo a | openssl enc -aes-128-cbc -K 3f786850e387550fdab836ed7e6dc881 -iv e387550fdab836ed7e6dc881de23001b -p -base64 -nosalt
    key=3F786850E387550FDAB836ED7E6DC881
    iv =E387550FDAB836ED7E6DC881DE23001B
    Zaf76KVeOWrs4UEWGqSReg==
    $ curl -s http://localhost:4567/api/v1/download/5618577aa4e6dc87931719ea26afbd7e886cb4e2 | base64
    Zaf76KVeOWrs4UEWGqSReg==
    $ curl -s http://localhost:4567/api/v1/recentfiles
    {"recentfiles":["5618577aa4e6dc87931719ea26afbd7e886cb4e2"],"filemax":200}
    $ curl -s http://localhost:4567/api/v1/tripcodelist
    {"tripcodelist":["hvfkN.qlp.zh"]}

## Contributing

1. Fork it ( https://github.com/ohac/iceberg/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Copyright and license

* Iceberg
  * The MIT License (MIT)
  * Copyright (c) 2014-2014 OHASHI Hideya
* jQuery
  * The MIT License (MIT)
* Twitter Bootstrap
  * The MIT License (MIT)
  * Copyright (c) 2011-2014 Twitter, Inc
* Bootstrap FileStyle
  * The MIT License (MIT)
* seedrandom.js
  * The MIT License (MIT)
  * Copyright 2015 David Bau.
* Crypto-js
  * New BSD License
  * (c) 2009-2013 by Jeff Mott. All rights reserved.
* jQuery BinaryTransport
  * The MIT License (MIT)
  * Copyright (c) 2014 Henry Algus
