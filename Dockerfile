FROM ubuntu:14.04.1

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y wget curl vim
RUN apt-get install -y redis-tools git ruby
RUN gem install redis
RUN gem install sinatra
RUN gem install haml
RUN apt-get install -y make ruby-dev g++
RUN gem install aws-sdk thin
RUN git clone https://github.com/ohac/iceberg.git
RUN \
  mkdir -p /iceberg/public/css && \
  mkdir -p /iceberg/public/js && \
  mkdir -p /iceberg/public/fonts && \
  cd /iceberg/public/css && \
  curl -sO https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap.min.css && \
  curl -sO https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap-theme.min.css && \
  cd /iceberg/public/js && \
  curl -sO https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/js/bootstrap.min.js && \
  cd /iceberg/public/fonts && \
  curl -sO https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/fonts/glyphicons-halflings-regular.woff && \
  curl -sO https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/fonts/glyphicons-halflings-regular.ttf
EXPOSE 4567
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
# (setup default.conf, cert.pem and cert.key)
# docker run --name bb -d -t -p 80:80 -p 443:443 busybox
# docker run --name rd -d --net container:bb \
#   -v $PWD/tmp/redis:/data redis redis-server --appendonly yes
# docker run --name nx -d --net container:bb \
#   -v $PWD/examples/docker/default.conf:/etc/nginx/conf.d/default.conf:ro \
#   -v $PWD/examples/docker/ssl:/data:ro nginx
# docker run --name ib -d --net container:bb \
#   -v $PWD/tmp/iceberg:/.iceberg -v $PWD/tmp/aws:/.aws:ro ohac/iceberg
