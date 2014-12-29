Iceberg

[![Build Status](https://travis-ci.org/ohac/iceberg.svg?branch=master)](https://travis-ci.org/ohac/iceberg)

Demo site: http://box.sighash.info/

example

    Server
    $ rackup -s thin -p 4567

    Client
    $ echo a > a
    $ sha1sum a
    3f786850e387550fdab836ed7e6dc881de23001b  a
    $ curl -F file=@a -F tripkey=a http://localhost:4567/api/v1/upload
    {"digest":"3f786850e387550fdab836ed7e6dc881de23001b","encdigest":"5618577aa4e6dc87931719ea26afbd7e886cb4e2","tripcode":"hvfkN.qlp.zh"}
    $ base64 ~/.iceberg/download/5618577aa4e6dc87931719ea26afbd7e886cb4e2 
    Zaf76KVeOWrs4UEWGqSReg==
    $ echo a | openssl enc -aes-128-cbc -K 3f786850e387550fdab836ed7e6dc881 -iv e387550fdab836ed7e6dc881de23001b -p -base64 -nosalt
    key=3F786850E387550FDAB836ED7E6DC881
    iv =E387550FDAB836ED7E6DC881DE23001B
    Zaf76KVeOWrs4UEWGqSReg==
