FROM ruby:2.4.2

COPY . /opt/sinatra
RUN cd /opt/sinatra \
  && bundle install
EXPOSE 8876

WORKDIR /opt/sinatra
CMD ["unicorn", "-d", "-c", "unicorn.conf"]

