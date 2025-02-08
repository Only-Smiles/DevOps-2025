require 'sinatra/base'
require 'sqlite3'
require 'bcrypt'
require 'erb'
require 'rack/session/cookie'
require 'securerandom'


class MiniTwit < Sinatra::Base
  SECRET_KEY = SecureRandom.hex(32)
  PER_PAGE = 30
  DATABASE = './db/minitwit.db'
  #set :views, File.dirname(__FILE__) + "/views"

  # Configure session management inside a configure block
  configure do
    use Rack::Session::Cookie, key: 'rack.session', secret: SECRET_KEY
  end

  # Database connection helper
  def connect_db
    SQLite3::Database.new(DATABASE, results_as_hash: true)
  end

  # Query helper
  def query_db(query, args = [], one = false)
    db = connect_db
    result = db.execute(query, args)
    db.close
    one ? result.first : result
  end

  # Get user ID by username
  def get_user_id(username)
    user = query_db('SELECT user_id FROM user WHERE username = ?', [username], true)
    user ? user['user_id'] : nil
  end

  # Format datetime
  def format_datetime(timestamp)
    Time.at(timestamp).utc.strftime('%Y-%m-%d @ %H:%M')
  end

  # Gravatar URL
  def gravatar_url(email, size = 80)
    hash = Digest::MD5.hexdigest(email.strip.downcase)
    "http://www.gravatar.com/avatar/#{hash}?d=identicon&s=#{size}"
  end

  # Before request
  before do
    @db = connect_db
    @user = session[:user_id] ? query_db('SELECT * FROM user WHERE user_id = ?', [session[:user_id]], true) : nil
  end

  # After request
  after do
    @db.close if @db
  end

  # Routes
  get '/' do
    redirect '/public' unless @user
    @messages = query_db('''
      SELECT message.*, user.* FROM message, user
      WHERE message.flagged = 0 AND message.author_id = user.user_id
      AND (user.user_id = ? OR user.user_id IN (SELECT whom_id FROM follower WHERE who_id = ?))
      ORDER BY message.pub_date DESC LIMIT ?''',
      [@user['user_id'], @user['user_id'], PER_PAGE])
    @title = @user + "'s Timeline"
    erb :timeline
  end

  get '/public' do
    puts "Views directory: #{settings.views}"
    @messages = query_db('''
      SELECT message.*, user.* FROM message, user
      WHERE message.flagged = 0 AND message.author_id = user.user_id
      ORDER BY message.pub_date DESC LIMIT ?''', [PER_PAGE])
    @title = "Public Timeline"
    erb :timeline
  end

  get '/login' do
    puts "Login page accessed!"
    @title = "Sign In"
    erb :login
  end

  post '/login' do
    puts "Login page accessed - post method!"
    user = query_db('SELECT * FROM user WHERE username = ?', [params[:username]], true)
    if user && BCrypt::Password.new(user['pw_hash']) == params[:password]
      session[:user_id] = user['user_id']
      redirect '/'
    else
      erb :login, locals: { error: 'Invalid username or password' }
    end
  end

  get '/register' do
    puts "Register page accessed!"
    erb :register
  end

  post '/register' do
    if params[:password] != params[:password2]
      erb :register, locals: { error: 'Passwords do not match' }
    else
      pw_hash = BCrypt::Password.create(params[:password])
      query_db('INSERT INTO user (username, email, pw_hash) VALUES (?, ?, ?)',
              [params[:username], params[:email], pw_hash])
      redirect '/login'
    end
  end

  get '/logout' do
    session.clear
    redirect '/public'
  end

  get '/:username' do
    @profile_user = query_db('SELECT * FROM user WHERE username = ?', [params[:username]], true)
    halt 404 unless @profile_user
    followed = @user && query_db('SELECT 1 FROM follower WHERE who_id = ? AND whom_id = ?', [@user['user_id'], @profile_user['user_id']], true)
    @messages = query_db('''
      SELECT message.*, user.* FROM message, user
      WHERE user.user_id = message.author_id AND user.user_id = ?
      ORDER BY message.pub_date DESC LIMIT ?''',
      [@profile_user['user_id'], PER_PAGE])
    erb :timeline, locals: { followed: followed }
  end

  post '/add_message' do
    halt 401 unless @user
    if params[:text] && !params[:text].empty?
      query_db('INSERT INTO message (author_id, text, pub_date, flagged) VALUES (?, ?, ?, 0)',
              [@user['user_id'], params[:text], Time.now.to_i])
      redirect '/'
    end
  end

  # Start the application
  run! if __FILE__ == $PROGRAM_NAME
end