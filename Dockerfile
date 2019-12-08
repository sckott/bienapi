FROM ruby:2.6.5

ENV JWT_SECRET='mysecret'
ENV JWT_ISSUER='bienapi.xyz'

COPY . /opt/sinatra
RUN cd /opt/sinatra \
  && bundle install
EXPOSE 8876

WORKDIR /opt/sinatra
CMD ["puma", "-C", "puma.rb"]
