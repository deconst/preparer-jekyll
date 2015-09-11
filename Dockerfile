FROM ruby:2.2.2
MAINTAINER Ash Wilson <ash.wilson@rackspace.com>

RUN mkdir -p /usr/src/app /usr/control-repo

WORKDIR /usr/src/app
COPY Gemfile /usr/src/app/Gemfile
COPY Gemfile.lock /usr/src/app/Gemfile.lock
COPY preparermd.gemspec /usr/src/app/preparermd.gemspec
COPY lib/preparermd/version.rb /usr/src/app/lib/preparermd/version.rb
RUN bundle install

COPY . /usr/src/app

VOLUME /usr/content-repo
WORKDIR /usr/content-repo

CMD ["ruby", "-I/usr/src/app/lib", "-rpreparermd", "-e", "PreparerMD.build"]
