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

  def req_from_sim(req)
    puts request.env['Authorization']
    from_sim = request.env['Authorization']
    if (from_sim != 'Basic c2ltdWxhdG9yOnN1cGVyX3NhZmUh')
       JSON({status: 403, 'error_msg': 'You are not authorized to use this resource!'})
    end 
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

  # Routes
  get '/' do
    redirect '/public' unless @user
    @messages = query_db('''
      SELECT message.*, user.* FROM message, user
      WHERE message.flagged = 0 AND message.author_id = user.user_id
      AND (user.user_id = ? OR user.user_id IN (SELECT whom_id FROM follower WHERE who_id = ?))
      ORDER BY message.pub_date DESC LIMIT ?''',
      [@user['user_id'], @user['user_id'], PER_PAGE])
    @title = "My Timeline"
#    # erb :timeline
  end

  get '/public' do
    @messages = query_db('''
      SELECT message.*, user.* FROM message, user
      WHERE message.flagged = 0 AND message.author_id = user.user_id
      ORDER BY message.pub_date DESC LIMIT ?''', [PER_PAGE])
    @title = "Public Timeline"
    # erb :timeline
  end

  get '/login' do
    @title = "Sign In"
    # erb :login
  end

  post '/login' do
    @user = query_db('SELECT * FROM user WHERE username = ?', [params[:username]], true)
    if @user && BCrypt::Password.new(@user['pw_hash']) == params[:password]
      session[:user_id] = @user['user_id']
      # flash[:notice] = 'You were logged in'
      redirect '/'
    elsif @user.nil?
      @error = 'Invalid username'
      # erb :login
    elsif BCrypt::Password.new(@user['pw_hash']) != params[:password]
      @error = 'Invalid password'
      # erb :login
    end
  end

  get '/register' do
    @title = "Sign Up"
    # erb :register
  end

  post '/register' do
    content_type :json

    puts @data
    @username = @data['username']
    @email = @data['email']
    password = @data['pwd']
  
    if @username.empty?
      status 400
      body JSON({ 'error': "MissingUsername", 'message': "You have to enter a username" })
    elsif @email.empty? || !@email.include?('@')
      status 400
      body JSON({ 'error': "MissingEmail", 'message': "You have to enter a valid email address" })
    elsif password.empty?
      status 400
      body JSON({ 'error': "MissingPassowrd", 'message': "You have to enter a password" })
    elsif !query_db('SELECT * FROM user WHERE username = ?', [@username], true).nil?
      body JSON({ 'error': "UsernameTaken", 'message': "Username is already taken." })
    else
      # Store the new user in the database
      password_hash = BCrypt::Password.create(password)
      query_db('INSERT INTO user (username, email, pw_hash) VALUES (?, ?, ?)', [@username, @email, password_hash.to_s])
      # Redirect to login page after successful registration
      status 200
      body JSON({ 'message': 'Account creation successful' })
    end
  end

  get '/logout' do
    session.clear
    # flash[:notice] = "You were logged out"
    redirect '/public'
  end

  get '/:username' do
    @profile_user = query_db('SELECT * FROM user WHERE username = ?', [params[:username]], true)
    halt 404 unless @profile_user
    followedresult = @user ? query_db('SELECT COUNT(*) AS count FROM follower WHERE who_id = ? AND whom_id = ?', [@user['user_id'], @profile_user['user_id']]) : [{ 'count' => 0 }]
    followed = followedresult.first['count'].to_i > 0
    @messages = query_db('''
      SELECT message.*, user.* FROM message, user
      WHERE user.user_id = message.author_id AND user.user_id = ?
      ORDER BY message.pub_date DESC LIMIT ?''',
      [@profile_user['user_id'], PER_PAGE])
    @title = "#{params[:username]}'s Timeline"
    # erb :timeline, locals: { followed: followed }
  end

  post '/add_message' do
    halt 401 unless @user
    if params[:text] && !params[:text].empty?
      query_db('INSERT INTO message (author_id, text, pub_date, flagged) VALUES (?, ?, ?, 0)',
              [@user['user_id'], params[:text], Time.now.to_i])
      
      # flash[:notice] = "Your message was recorded"
      redirect '/'
    end
  end


  post '/fllws/:username' do 
    # Left out while testing TODO: Testing does give Authorization token so use that 
    # req = req_from_sim(request)
    # return req unless req.nil?

    halt 401, "Unauthorized" unless @user
    whom_id = get_user_id(@data['username'])
    halt 404, "User not found" unless whom_id

    if @data.key?('unfollow')
      query_db('DELETE FROM follower WHERE who_id = ? AND whom_id = ?', [@user['user_id'], whom_id])  
      status 200
      body JSON({ 'message': 'Unfollowed #{whom_id}' })
    elsif @data.key?('follow')
      query_db('INSERT INTO follower (who_id, whom_id) VALUES (?, ?)', [@user['user_id'], whom_id])
      status 200
      body JSON({ 'message': 'Followed #{whom_id}',  })
    end
  end


  get '/fllws/:username' do
    # write request to some txt bc that's who we are apparently (see og)
    # req = req_from_sim(request)
    # return req unless req.nil?
    halt 404 unless @user
    no_followers = request.env['no'] || 100
    followers = query_db('SELECT u.username FROM user u
            INNER JOIN follow f on f.whom_id=u.user_id
            WHERE f.who_id = ?
            LIMIT ?', [@user['user_id'], no_followers])
    follower_names = followers.map{|x| x['username']}
    JSON({'follows': follower_names})
  end 

  # Start the application
  run! if __FILE__ == $PROGRAM_NAME

end
