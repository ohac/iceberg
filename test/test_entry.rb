require 'iceberg'

b = Iceberg::Storage.new
b.dir
b.create
b.dir
o = b.getobject('testfile')
o.key
o.exists?
o.content_length
o.write('hello')
o.close
o.read
o.close
o.delete
