require 'sinatra/base'
require 'json'
require 'sqlite3'
require 'bcrypt'
require 'rack/session/cookie'
require 'securerandom'

class MiniTwit < Sinatra::Base
  SECRET_KEY = SecureRandom.hex(32)
  PER_PAGE = 30
  DATABASE = './db/minitwit.db'
  
  # Configure session management inside a configure block
  configure do
    enable :sessions
    use Rack::Session::Cookie, key: 'rack.session', secret: SECRET_KEY
  end


  # Before request
  before do
    @db = connect_db(DATABASE)
    @user = session[:user_id] ? query_db('SELECT * FROM user WHERE user_id = ?', [session[:user_id]], true) : nil
    # Parse JSON request body
    begin
      content_type :json
      request.body.rewind
      @data = JSON.parse(request.body.read)
    rescue JSON::ParserError
      status 401
      body JSON({ 'error': 'InvalidJSON', 'message': 'Invalid JSON format' })
    end
  end

  # After request
  after do
    @db.close if @db
  end

  # Note that 'helpers' is sinatra way of naming 'utils'
  require_relative 'helpers/init'
  require_relative 'api/init'

  # Start the application
  run! if __FILE__ == $PROGRAM_NAME

end
