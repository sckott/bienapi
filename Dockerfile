FROM ruby:2.7.1

MAINTAINER Scott Chamberlain <sckott@protonmail.com>

RUN apt-get update \
  && apt-get install nano

RUN gem install pry \
  && pry --version

RUN JQ_URL="https://circle-downloads.s3.amazonaws.com/circleci-images/cache/linux-amd64/jq-latest" \
  && curl --silent --show-error --location --fail --retry 3 --output /usr/bin/jq $JQ_URL \
  && chmod +x /usr/bin/jq \
  && jq --version

COPY . /opt/sinatra
RUN cd /opt/sinatra \
  && bundle install
EXPOSE 8876

WORKDIR /opt/sinatra
CMD ["puma", "-C", "puma.rb"]
