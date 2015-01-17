require 'iceberg'

b = Iceberg::Storage.new
b.dir
o = b.getobject('testfile')
o.size
o.write('hello')
o.close
o.read
o.close
o.rm
