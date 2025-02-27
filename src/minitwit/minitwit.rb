require 'sinatra/base'
require 'json'
require 'rack-flash'
require 'sqlite3'
require 'bcrypt'
require 'erb'
require 'rack/session/cookie'
require 'securerandom'
require 'digest/md5'

# Require helpers and controllers
Dir["./helpers/*.rb"].each {|file| require file }
require './controllers/base_controller'
require './controllers/web_controller'
require './controllers/api_controller'

class MiniTwit < Sinatra::Base
  SECRET_KEY = SecureRandom.hex(32)
  PER_PAGE = 30
  DATABASE = '../test/artifacts/test.db'
  
  configure do
    enable :sessions
    use Rack::Session::Cookie, key: 'rack.session', secret: SECRET_KEY
    use Rack::Flash
  end

  # Mount controllers
  use WebController
  use ApiController
end
