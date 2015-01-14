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
# docker build -t ohac/iceberg .
# docker run --link redis:db --name iceberg -p 4567:4567 -d ohac/iceberg
# docker run --link redis:db --name iceberg -p 4567:4567 -i -t --rm ohac/iceberg bash
