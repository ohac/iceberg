Iceberg

[![Build Status](https://travis-ci.org/ohac/iceberg.svg?branch=master)](https://travis-ci.org/ohac/iceberg)

Demo site: http://box.sighash.info/

    example
    
    $ rackup -s thin -p 4567
    $ curl -F file=@foo.bin -F tripkey=a http://localhost:4567/api/v1/upload
