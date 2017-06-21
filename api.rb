require 'bundler/setup'
%w(yaml json digest redis).each { |req| require req }
Bundler.require(:default)
require 'sinatra'
require_relative 'models/models'

# feature flag: toggle redis
$use_redis = true

$config = YAML::load_file(File.join(__dir__, ENV['RACK_ENV'] == 'test' ? 'test_config.yaml' : 'config.yaml'))

$redis = Redis.new host: ENV.fetch('REDIS_PORT_6379_TCP_ADDR', 'localhost'),
                   port: ENV.fetch('REDIS_PORT_6379_TCP_PORT', 6379)

ActiveSupport::Deprecation.silenced = true
ActiveRecord::Base.establish_connection($config['db'])

class API < Sinatra::Application
  before do
    # puts '[env]'
    # p env
    # puts '[Params]'
    # p params

    $route = request.path

    # set headers
    headers 'Content-Type' => 'application/json; charset=utf8'
    headers 'Access-Control-Allow-Methods' => 'HEAD, GET'
    headers 'Access-Control-Allow-Origin' => '*'
    cache_control :public, :must_revalidate, max_age: 60

    # prevent certain verbs
    if request.request_method != 'GET'
      halt 405
    end

    # use redis caching
    if $config['caching'] && $use_redis
      if request.path_info != "/"
        @cache_key = Digest::MD5.hexdigest(request.url)
        if $redis.exists(@cache_key)
          headers 'Cache-Hit' => 'true'
          halt 200, $redis.get(@cache_key)
        end
      end
    end

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

  configure do
    mime_type :apidocs, 'text/html'
  end

  # handle missed route
  not_found do
    halt 404, { error: 'route not found' }.to_json
  end

  # handle other errors
  error do
    halt 500, { error: 'server error' }.to_json
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

  # default to landing page
  ## used to go to /heartbeat
  get '/?' do
    content_type :apidocs
    send_file File.join(settings.public_folder, '/index.html')
  end

  # route listing route
  get '/heartbeat/?' do
    db_routes = Models.models.map do |m|
      "/#{m.downcase}#{Models.const_get(m).primary_key ? '/:id' : '' }?<params>"
    end
    { routes: %w( /heartbeat /list /list/country /plot/dataset ) + db_routes }.to_json
  end

  # generate routes from the models
  Models.models.each do |model_name|
    model = Models.const_get(model_name)
    get "/#{model_name.to_s.downcase}/?#{model.primary_key ? ':id?/?' : '' }" do
      begin
        data = model.endpoint(params)
        raise Exception.new('no results found') if data.length.zero?
        { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }.to_json
      rescue Exception => e
        halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
      end
    end
  end

  get '/list/?' do
    begin
      data = List.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }.to_json
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

  get '/list/country/?' do
    begin
      data = ListCountry.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }.to_json
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

  get '/plot/dataset/?' do
    begin
      data = PlotDataset.endpoint(params)
      raise Exception.new('no results found') if data.length.zero?
      { count: data.limit(nil).count(1), returned: data.length, data: data, error: nil }.to_json
    rescue Exception => e
      halt 400, { count: 0, returned: 0, data: nil, error: { message: e.message }}.to_json
    end
  end

end
