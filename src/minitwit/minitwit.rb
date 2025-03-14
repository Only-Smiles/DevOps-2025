require 'sinatra/base'
require 'json'
require 'rack-flash'
require 'sqlite3'
require 'bcrypt'
require 'erb'
require 'rack/session/cookie'
require 'securerandom'
require 'digest/md5'
require 'sequel'
require 'dotenv/load'

# Require helpers and controllers
Dir[File.join(__dir__, 'helpers/*.rb')].sort.each { |file| require file }
require_relative 'controllers/base_controller'
require_relative 'controllers/web_controller'
require_relative 'controllers/api_controller'

class MiniTwit < Sinatra::Base
  SECRET_KEY = SecureRandom.hex(32)
  PER_PAGE = 30
  DATABASE = "postgres://#{ENV.fetch('DB_USER', nil)}:#{ENV.fetch('DB_PWD', nil)}@database:5432/minitwit"

  configure do
    enable :sessions
    use Rack::Session::Cookie, key: 'rack.session', secret: SECRET_KEY
    use Rack::Flash
  end

  configure :development, :test do
    ['localhost', '127.0.0.1', 'minitwit']
  end

  # Mount controllers
  use WebController
  use ApiController
end
