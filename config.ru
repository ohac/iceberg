require File.dirname( __FILE__ ) + '/bin/icebergd'

Iceberg::WebApp.set :protection, :except => :frame_options
run Iceberg::WebApp
