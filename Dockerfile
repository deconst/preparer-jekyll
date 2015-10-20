FROM alpine:3.2
MAINTAINER Ash Wilson <ash.wilson@rackspace.com>

RUN apk add --update ruby ruby-json ruby-dev git build-base libffi-dev nodejs python \
  && rm -rf /var/cache/apk/* \
  && rm -rf /usr/share/ri
RUN gem install bundler --no-rdoc --no-ri

RUN mkdir -p /usr/src/app /usr/content-repo

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
