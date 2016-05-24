require 'json'
require_relative 'lib/constants'
require_relative 'model/all_models.rb'
require_relative 'lib/anidb_resource_fetcher.rb'
require 'bundler/setup'
require 'sinatra/base'
require 'tilt/erb'

require 'logger'

class App < Sinatra::Application
  configure do
    enable :logging
    # logfile = File.expand_path('../../data/anidb.log', __FILE__)
    # logger = Logger.new(logfile).tap {|l| l.level = $DEBUG ? Logger::DEBUG : Logger::INFO}
    # use Rack::CommonLogger, logger
  end  

  set :static_cache_control, [:no_cache, :must_revalidate, max_age: 0]
  set :public_folder, 'public'

  before do
    content_type 'application/json'
  end

  get "/" do
    redirect '/index.html'
  end

  get "/shows/:id" do
    Show.exists?(params[:id]) ? Show.get(params[:id]) : not_found
  end

  get "/shows" do
    Show.all.to_json
  end

  post "/shows/new" do
    begin
      @show = Show.new(params[:id], params[:name], params[:feed], params[:auto_fetch])
      @show.save.to_json
    rescue
      [400, @show.errors.to_json]
    end  
  end

  # put "/shows/:id" do
  #   @show = Show.get params[:id]
  #   @show.aid = params[:aid]
  #   show.save.to_json
  # end

  get "/anidb/:aid.xml" do
    content_type 'application/xml'
    send_file AnidbResourceFetcher.data(params[:aid])
  end

  get "/anidb/thumb/:aid.jpg" do
    content_type 'image/jpeg'
    send_file AnidbResourceFetcher.thumb(params[:aid])
  end  
end  
