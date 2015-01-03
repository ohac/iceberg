require File.dirname( __FILE__ ) + '/bin/icebergd'

set :protection, :except => :frame_options
run Sinatra::Application
