FROM ruby:2.2.2
MAINTAINER Ash Wilson <ash.wilson@rackspace.com>

RUN mkdir -p /usr/src/app /usr/control-repo

WORKDIR /usr/src/app
COPY . /usr/src/app
RUN rake install

VOLUME /usr/control-repo
WORKDIR /usr/control-repo

CMD ["ruby", "-I/usr/src/app", "-rpreparermd", "-e", "PreparerMD.build"]
