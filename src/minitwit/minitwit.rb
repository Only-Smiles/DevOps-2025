require 'sinatra/base'
require 'json'
require 'rack-flash'
require 'bcrypt'
require 'erb'
require 'rack/session/cookie'
require 'securerandom'
require 'digest/md5'
require 'sequel'
require 'dotenv/load'
require 'redis'
require 'redis-rack'
require 'logger'

puts '[BOOT] MiniTwit loaded'
$stdout.sync = true # still useful in Docker
LOGGER = Logger.new($stdout)
LOGGER.level = Logger::DEBUG

# Require helpers and controllers
Dir[File.join(__dir__, 'helpers/*.rb')].sort.each { |file| require file }
require_relative 'controllers/base_controller'
require_relative 'controllers/web_controller'
require_relative 'controllers/api_controller'

class MiniTwit < Sinatra::Base
  SECRET_KEY = SecureRandom.hex(32)
  PER_PAGE = 30
  DATABASE = "postgres://#{ENV.fetch('DB_USER', nil)}:#{ENV.fetch('DB_PWD', nil)}@database:5432/minitwit"
  REDIS_URL = ENV.fetch('REDIS_URL', 'redis://redis:6379/0')

  configure do
    enable :logging
    set :logger, LOGGER
    enable :sessions

    # Use Redis for session storage
    use Rack::Session::Redis, {
      redis_server: REDIS_URL,
      key: 'rack.session',
      secret: SECRET_KEY,
      expire_after: 86_400 # 1 day in seconds
    }

    use Rack::Flash
  end

  configure :development, :test do
    ['localhost', '127.0.0.1', 'minitwit']
  end

  # Mount controllers
  use WebController
  use ApiController
end
