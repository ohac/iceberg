FROM ubuntu:14.04.1

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y wget curl vim
RUN apt-get install -y redis-tools git ruby
RUN gem install redis
RUN gem install sinatra
RUN gem install haml
RUN git clone https://github.com/ohac/iceberg.git
EXPOSE 4567
RUN apt-get install -y make ruby-dev g++
RUN gem install thin
WORKDIR /iceberg
CMD rackup -p 4567 -o 0.0.0.0

# Build:
# docker build -t ohac/iceberg .
#
# Run (standalone):
# docker run --name redis -d \
#   -v /somewhere/redis:/data redis redis-server --appendonly yes
# docker run --name iceberg -d --link redis:db -p 4567:4567 \
#   -v /somewhere/iceberg:/root/.iceberg ohac/iceberg
#
# Run (with nginx):
# (setup nginx.conf, server.crt and server.key)
# docker run --name nginx -d -p 443:443 -p 80:80 \
#   -v /somewhere/nginx.conf:/etc/nginx/nginx.conf:ro \
#   -v /somewhere/ssl:/data:ro nginx
# docker run --name redis -d --net container:nginx \
#   -v /somewhere/redis:/data redis redis-server --appendonly yes
# docker run --name iceberg -d --net container:nginx \
#   -v /somewhere/iceberg:/root/.iceberg ohac/iceberg
