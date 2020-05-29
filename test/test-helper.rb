# frozen_string_literal: true

# require 'vcr'

# VCR.configure do |config|
#   config.cassette_library_dir = 'test/vcr_cassettes'
#   config.hook_into :webmock
# end

require 'faraday'
require 'multi_json'

bien_base="https://bienapi.xyz"

user_agent = "Faraday v" + Faraday::VERSION + "/testing-bienapi"

$bien_conn=Faraday.new(url: bien_base)
$bien_conn.headers[:user_agent] = user_agent

$bien_conn_auth=Faraday.new(url: bien_base)
$bien_conn_auth.headers[:user_agent] = user_agent
$bien_conn_auth.headers[:authorization] = ENV["BIEN_API_KEY"]
