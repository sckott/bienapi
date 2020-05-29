require 'bundler/setup'
%w(yaml json digest redis csv).each { |req| require req }
Bundler.require(:default)
require 'sinatra'
require "sinatra/multi_route"
require 'mongo'

require_relative 'funs'
require_relative 'models/models'

# feature flag: toggle redis
$use_redis = true

# mongo
mongo_host = [ ENV.fetch('MONGO_PORT_27017_TCP_ADDR') + ":" + ENV.fetch('MONGO_PORT_27017_TCP_PORT') ]
client_options = {
  :database => 'bienusers',
  :user => ENV.fetch('BIEN_MONGO_USER'),
  :password => ENV.fetch('BIEN_MONGO_PWD'),
  :max_pool_size => 25,
  :connect_timeout => 15,
  :wait_queue_timeout => 15
}
mongo = Mongo::Client.new(mongo_host, client_options)
# mongo = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'bienusers')
$busers = mongo[:users]

# api key
$api_key = ENV['BIEN_API_KEY']

$config = YAML::load_file(File.join(__dir__, ENV['RACK_ENV'] == 'test' ? 'test_config.yaml' : 'config.yaml'))
$config = YAML::load_file(File.join(__dir__, 'config.yaml'))

$redis = Redis.new host: ENV.fetch('REDIS_PORT_6379_TCP_ADDR', 'localhost'),
                   port: ENV.fetch('REDIS_PORT_6379_TCP_PORT', 6379)

ActiveSupport::Deprecation.silenced = true
ActiveRecord::Base.establish_connection($config['db'])
ActiveRecord::Base.logger = Logger.new(STDOUT)

class API < Sinatra::Application
  configure do
    enable :logging
    set :dump_errors, false
    set :raise_errors, false
    set :show_exceptions, false
    set :server, :puma
    set :protection, :except => [:json_csrf]
  end

  # handle missed route
  not_found do
    halt 404, { error: 'route not found' }.to_json
  end

  # handle other errors
  error do
    halt 500, { error: 'server error' }.to_json
  end

  # method not allowed
  error 405 do
    halt 405, {'Content-Type' => 'application/json'}, JSON.generate({ 'error' => 'Method Not Allowed' })
  end

  # unsupported media type
  error 415 do
    halt 415, { error: 'Unsupported media type', message: 'supported media types are application/json, text/csv' }.to_json
  end

  $paths_to_ignore = ["/", "/heartbeat", "/heartbeat/", "/token", "/token/"]

  before do
    puts '[env]'
    p env
    puts '[Params]'
    p params
    # puts '[Authorization]'
    # p request.env['HTTP_AUTHORIZATION'].slice(7..-1)

    $route = request.path

    # set headers
    headers 'Content-Type' => 'application/json; charset=utf8'
    headers 'Access-Control-Allow-Methods' => 'HEAD, GET'
    headers 'Access-Control-Allow-Origin' => '*'
    headers 'Strict-Transport-Security' => 'max-age=86400; includeSubDomains'
    cache_control :public, :must_revalidate, max_age: 60

    # use redis caching
    if $config['caching'] && $use_redis && authorized?
      if !$paths_to_ignore.include? request.path_info
        @cache_key = Digest::MD5.hexdigest(request.url)
        if $redis.exists(@cache_key)
          headers 'Cache-Hit' => 'true'
          halt 200, $redis.get(@cache_key)
        end
      end
    end

    def content_type_ok?
      ctype = request.env['CONTENT_TYPE']
      ['application/json', 'text/csv'].include? ctype
    end

    415 unless content_type_ok?
    pass if %w[/ /heartbeat /heartbeat/].include? request.path_info
    # halt 401, { error: 'not authorized' }.to_json unless !request.env['HTTP_AUTHORIZATION'].nil?
    # httpauth = request.env['HTTP_AUTHORIZATION'] || ""
    # halt 401, { error: 'not authorized' }.to_json unless valid_key?(httpauth.slice(7..-1))
  end

  after do
    # cache response in redis
    if $config['caching'] &&
      $use_redis &&
      !response.headers['Cache-Hit'] &&
      response.status == 200 &&
      request.path_info != "/" &&
      request.path_info != ""

      $redis.set(@cache_key, response.body[0], ex: $config['caching']['expires'])
    end
  end

  helpers do
    def valid_key?(key)
      key == $api_key
    end

    def serve_data(ha, data)
      # puts '[CONTENT_TYPE]'
      # puts request.env['CONTENT_TYPE'].nil?
      case request.env['CONTENT_TYPE']
      when 'application/json'
        ha.to_json
      when 'text/csv'
        to_csv(data)
      when nil
        ha.to_json
      else
        415
      end
    end

    # if method not allowed, halt with error
    def halt_method(x = ['GET'])
      if !x.include?(request.request_method)
        halt 405
      end
    end
  end

  configure do
    mime_type :apidocs, 'text/html'
    mime_type :csv, 'text/csv'
  end

  # handler - redirects any /foo -> /foo/
  #  - if has any query params, passes to handler as before
  # get %r{(/.*[^\/])$} do
  #   if request.query_string == "" or request.query_string.nil?
  #     redirect request.script_name + "#{params[:captures].first}/"
  #   else
  #     pass
  #   end
  # end

  def valid_email?(email)
    raise Exception.new("an email must be given") unless not email.nil?
    res = EmailAddress.error email
    if not res.nil?
      if res.empty?
        res = "email string given doesn't appear to be an email address"
      end
      halt 403, { error: { message: res }}.to_json
    end
  end

  def token_make(email)
    valid_email? email
    tg = token_get(email)
    if tg.nil?
      # email not found, create token
      tok = SecureRandom.urlsafe_base64.gsub(/[^0-9a-zA-Z]/i, '')
      # on successful token creation, store in database
      $busers.insert_one({ email: email, token: tok })
      x = $busers.find({ email: params[:email] }).first
      x.delete("_id")
      return x
    else
      # email found, give back token
      return tg
    end
  end

  def token_get(email)
    valid_email? email
    res = $busers.find({ email: params[:email] }).first
    return res unless not res.nil?
    res.delete("_id")
    return res
  end

  get '/token/?' do
    begin
      tok = token_make(params[:email])
      content_type :json
      tok.to_json
    rescue Exception => e
      halt 400, { error: { message: e.message }}.to_json
    end
  end

  def token_valid?(x)
    if $busers.find({ token: x }).count != 1
      raise Exception.new("token not found; get a token first with the /token route")
    end
  end

  def authorized?
    return true if $paths_to_ignore.include? request.path_info
    tok = env.fetch('HTTP_AUTHORIZATION', nil)
    if tok.nil?
      content_type :json
      halt 401, { error: 'A token must be given in the Authorization header' }.to_json
    end

    begin
      token_valid? tok
    rescue Exception => e
      content_type :json
      halt 403, { error: e.message }.to_json
    end

    return true
  end

  get '/authorized/?' do
    authorized?
    content_type :json
    { authorized: true }.to_json
  end

  # default to landing page
  ## used to go to /heartbeat
  get '/?' do
    halt_method
    content_type :apidocs
    send_file File.join(settings.public_folder, '/index.html')
  end

  # route listing route
  get '/heartbeat/?' do
    { routes: API.routes["GET"].map{ |w| w[0].to_s } }.to_json
  end

  # generate routes from the models
  # Models.models.each do |model_name|
  #   model = Models.const_get(model_name)
  #   get "/#{model_name.to_s.downcase}/?#{model.primary_key ? ':id?/?' : '' }" do
  #     begin
  #       data = model.endpoint(params)
  #       raise Exception.new('no results found') if data.length.zero?
  #       ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
  #       serve_data(ha, data)
  #     rescue Exception => e
  #       halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
  #     end
  #   end
  # end

  get '/list/?' do
    authorized?
    halt_method
    begin
      data = List.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

  get '/list/country/?' do
    authorized?
    halt_method
    begin
      data = ListCountry.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end


  # plot routes
  get '/plot/metadata/?' do
    authorized?
    halt_method
    begin
      data = PlotMetadata.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

  ## List available sampling protocols
  get '/plot/protocols/?' do
    authorized?
    halt_method
    begin
      data = PlotProtocols.endpoint
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

  ## Get a sampling protocol by name
  # get '/plot/protocols/:protocol/?' do
  #   authorized?
  #   halt_method
  #   begin
  #     data = PlotSamplingProtocol.endpoint(params)
  #     raise Exception.new('no results found') if data.length.zero?
  #     ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
  #     serve_data(ha, data)
  #   rescue Exception => e
  #     halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
  #   end
  # end

  ## Plot data by plot name
  # get '/plot/name/?' do
  #   halt_method
  #   begin
  #     data = PlotName.endpoint(params)
  #     raise Exception.new('no results found') if data.length.zero?
  #     ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
  #     serve_data(ha, data)
  #   rescue Exception => e
  #     halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
  #   end
  # end

  # trait routes
  ## all traits
  get '/traits/?' do
    authorized?
    halt_method
    begin
      data = Traits.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

  ## traits by family
  get '/traits/family/?' do
    authorized?
    halt_method
    begin
      data = TraitsFamily.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

  ## trait id by family
  get '/traits/family/:id/?' do
    # call env.merge("PATH_INFO" => '/traits/family/')
    authorized?
    halt_method
    begin
      data = TraitsFamilyId.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

  # occurrence routes
  ## species
  get '/occurrence/species/?' do
    authorized?
    halt_method
    begin
      data = OccurrenceSpecies.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: nil, returned: data.size, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

  ## genus
  get '/occurrence/genus/?' do
    authorized?
    halt_method
    begin
      data = OccurrenceGenus.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: nil, returned: data.size, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

  ## family
  get '/occurrence/family/?' do
    authorized?
    halt_method
    begin
      data = OccurrenceFamily.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: nil, returned: data.size, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

  ## family
  post '/occurrence/spatial/?' do
    authorized?
    halt_method(['POST'])
    begin
      data = OccurrenceSpatial.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil ).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

  # count
  get '/occurrence/count/?' do
    authorized?
    halt_method
    begin
      data = OccurrenceCount.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil ).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end


  # taxonomy routes
  ## by species
  get '/taxonomy/species/?' do
    authorized?
    begin
      halt_method
      data = TaxonomySpecies.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.backtrace }}.to_json
    end
  end

  # phylogeny route
  get '/phylogeny/?' do
    authorized?
    begin
      halt_method
      data = Phylogeny.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

  # meta routes
  get '/meta/version/?' do
    authorized?
    begin
      halt_method
      data = MetaVersion.endpoint
      raise Exception.new('no results found') if data.length.zero?
      ha = { data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { data: nil, error: { message: e.message }}.to_json
    end
  end

  get '/meta/citations/traits/:id/?' do
    authorized?
    begin
      halt_method
      data = CitationsTrait.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { data: nil, error: { message: e.message }}.to_json
    end
  end
  get '/meta/citations/occurrence/:id/?' do
    authorized?
    begin
      halt_method
      data = CitationsOccurrence.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { data: nil, error: { message: e.message }}.to_json
    end
  end

  get '/meta/politicalnames/?' do
    authorized?
    begin
      halt_method
      data = MetaPoliticalNames.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end



  # ranges routes
  get '/ranges/list/?' do
    authorized?
    begin
      halt_method
      data = RangesList.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

  get '/ranges/species/?' do
    authorized?
    begin
      halt_method
      data = RangesSpecies.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

  get '/ranges/genus/?' do
    authorized?
    begin
      halt_method
      data = RangesGenus.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

  get '/ranges/spatial/?' do
    authorized?
    begin
      halt_method
      data = RangesSpatial.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end



  # stem routes
  get '/stem/species/?' do
    authorized?
    begin
      halt_method
      data = StemSpecies.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

  get '/stem/genus/?' do
    authorized?
    begin
      halt_method
      data = StemGenus.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

  get '/stem/family/?' do
    authorized?
    begin
      halt_method
      data = StemFamily.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

  get '/stem/datasource/?' do
    authorized?
    begin
      halt_method
      data = StemDataSource.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      ha = { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }
      serve_data(ha, data)
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end



  # prevent some routes
  route :copy, :patch, :put, :post, :options, :trace, :delete, '/*' do
    halt 405
  end

end
