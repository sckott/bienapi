FROM ruby:2.7.0

RUN gem install pry \
  && pry --version

COPY . /opt/sinatra
RUN cd /opt/sinatra \
  && bundle install
EXPOSE 8876

WORKDIR /opt/sinatra
CMD ["puma", "-C", "puma.rb"]
