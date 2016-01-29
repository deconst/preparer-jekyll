FROM alpine:3.3
MAINTAINER Ash Wilson <ash.wilson@rackspace.com>

RUN apk add --no-cache ruby ruby-io-console ruby-irb ruby-rdoc ruby-dev \
  git build-base libffi-dev nodejs python

RUN adduser -D -g "" -u 1000 preparer
RUN mkdir -p /usr/src/app /usr/content-repo
RUN chown -R preparer:preparer /usr/src/app

USER preparer

WORKDIR /usr/src/app
ENV GEM_HOME /usr/src/app/.gems
ENV PATH ${PATH}:/usr/src/app/.gems/bin

RUN gem install bundler --no-rdoc --no-ri

COPY Gemfile /usr/src/app/Gemfile
COPY Gemfile.lock /usr/src/app/Gemfile.lock
COPY preparermd.gemspec /usr/src/app/preparermd.gemspec
COPY lib/preparermd/version.rb /usr/src/app/lib/preparermd/version.rb
RUN bundle install

COPY . /usr/src/app

VOLUME /usr/content-repo
WORKDIR /usr/content-repo

CMD ["ruby", "-I/usr/src/app/lib", "-rpreparermd", "-e", "PreparerMD.build"]
