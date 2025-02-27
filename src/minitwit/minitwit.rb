require 'sinatra/base'
require 'json'
require 'rack-flash'
require 'sqlite3'
require 'bcrypt'
require 'erb'
require 'rack/session/cookie'
require 'securerandom'

class MiniTwit < Sinatra::Base
  SECRET_KEY = SecureRandom.hex(32)
  PER_PAGE = 30
  DATABASE = '../../test/artifacts/test.db'
  
  # Configure session management inside a configure block
  configure do
    enable :sessions
    use Rack::Session::Cookie, key: 'rack.session', secret: SECRET_KEY
    use Rack::Flash
  end

  # Before all requests
  before do
    @db = connect_db(DATABASE)
    @user = session[:user_id] ? query_db('SELECT * FROM user WHERE user_id = ?', [session[:user_id]], true) : nil

    #ph = BCrypt::Password.create(params[:pwd]).to_s
    #@user = query_db('SELECT * FROM user WHERE username = ? AND pw_hash = ?', [params[:username], ph], true)

  end


  # Before api requests
  ['/api', '/api/*'].each do |path|
    before path do
      # Parse JSON request body
      content_type :json
      begin
        @latest = params[:latest]
        @data = JSON.parse(request.body.read)
      rescue JSON::ParserError
        status 401
        body JSON({ 'error': 'InvalidJSON', 'message': 'Invalid JSON format' })
      end
    end
  end



  # After request
  after do
    if !@latest.nil?
      file_path = File.join(File.dirname(__FILE__), 'api/latest_processed_sim_action_id.txt')
      File.write(file_path, @latest)
    end

    @db.close if @db
  end

  # Note that 'helpers' is sinatra way of naming 'utils'
  require_relative 'helpers/init'
  require_relative 'api/init'
  require_relative 'frontend/init'

  # Start the application
  run! if __FILE__ == $PROGRAM_NAME

end
