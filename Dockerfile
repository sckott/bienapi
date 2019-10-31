FROM ruby:2.6.5

COPY . /opt/sinatra
RUN cd /opt/sinatra \
  && bundle install
EXPOSE 8876

USER bien_api

WORKDIR /opt/sinatra
CMD ["unicorn", "-d", "-c", "unicorn.conf"]

