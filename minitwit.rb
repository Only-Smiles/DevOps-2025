# -*- coding: utf-8 -*-
=begin
    MiniTwit
    ~~~~~~~~

    A microblogging application written with Flask and sqlite3.

    :copyright: (c) 2010 by Armin Ronacher.
    :license: BSD, see LICENSE for more details.
=end

require 'sinatra'
require 'sinatra/flash'
require 'sqlite3'
require 'digest/md5'
require 'time'
require 'date'
require 'bcrypt'

# configuration
DATABASE = './tmp/minitwit.db'
PER_PAGE = 30
DEBUG = true
SECRET_KEY = 'development key'

configure do
  enable :sessions
  set :session_secret, SECRET_KEY
  set :bind, '0.0.0.0'
  set :port, 8080
  set :public_folder, File.dirname(__FILE__) + '/public'
  set :views, File.dirname(__FILE__) + '/views'
  set :show_exceptions, DEBUG
end

# create our little application :)
# In Sinatra the main app is this file.

def connect_db()
  """Returns a new connection to the database."""
  db = SQLite3::Database.new(DATABASE)
  db.results_as_hash = true
  return db
end

def init_db()
  """Creates the database tables."""
  db = connect_db()
  schema_path = File.join(settings.root, 'schema.sql')
  File.open(schema_path, "r") do |f|
    db.execute_batch(f.read)
  end
  db.close
end

def query_db(query, args = [], one = false)
  """Queries the database and returns a list of dictionaries."""
  rv = settings.db.execute(query, args)
  if one
    return rv.empty? ? nil : rv.first
  else
    return rv
  end
end

def get_user_id(username)
  """Convenience method to look up the id for a username."""
  rv = settings.db.get_first_row('select user_id from user where username = ?', [username])
  return rv ? rv['user_id'] : nil
end

def format_datetime(timestamp)
  """Format a timestamp for display."""
  return Time.at(timestamp).utc.strftime('%Y-%m-%d @ %H:%M')
end

def gravatar_url(email, size=80)
  """Return the gravatar image for the given email address."""
  hash = Digest::MD5.hexdigest(email.strip.downcase.force_encoding('UTF-8'))
  return "http://www.gravatar.com/avatar/#{hash}?d=identicon&s=#{size}"
end

before do
  # Make sure we are connected to the database each request and look
  # up the current user so that we know he's there.
  @db = connect_db()
  # Store the db connection in settings so that query_db and get_user_id can access it
  settings.db = @db
  @user = nil
  if session.key?('user_id')
    @user = query_db('select * from user where user_id = ?', [session['user_id']], true)
  end
end

after do
  # Closes the database again at the end of the request.
  @db.close if @db
end

get '/' do
  # Shows a users timeline or if no user is logged in it will
  # redirect to the public timeline.  This timeline shows the user's
  # messages as well as all the messages of followed users.
  puts "We got a visitor from: " + request.ip.to_s
  if !@user
    redirect to(url('/public'))
  end
  offset = params['offset'] ? params['offset'].to_i : nil
  messages = query_db(%{
        select message.*, user.* from message, user
        where message.flagged = 0 and message.author_id = user.user_id and (
            user.user_id = ? or
            user.user_id in (select whom_id from follower
                                    where who_id = ?))
        order by message.pub_date desc limit ?
        }, [session['user_id'], session['user_id'], PER_PAGE])
  erb :timeline, :locals => { :messages => messages }
end

get '/public' do
  # Displays the latest messages of all users.
  messages = query_db(%{
        select message.*, user.* from message, user
        where message.flagged = 0 and message.author_id = user.user_id
        order by message.pub_date desc limit ?
        }, [PER_PAGE])
  erb :timeline, :locals => { :messages => messages }
end

get '/:username' do
  # Display's a users tweets.
  username = params['username']
  profile_user = query_db('select * from user where username = ?', [username], true)
  halt 404 if profile_user.nil?
  followed = false
  if @user
    check = query_db(%{
            select 1 from follower where
            follower.who_id = ? and follower.whom_id = ?
        }, [session['user_id'], profile_user['user_id']], true)
    followed = !check.nil?
  end
  messages = query_db(%{
            select message.*, user.* from message, user where
            user.user_id = message.author_id and user.user_id = ?
            order by message.pub_date desc limit ?
        }, [profile_user['user_id'], PER_PAGE])
  erb :timeline, :locals => { :messages => messages, :followed => followed, :profile_user => profile_user }
end

get '/:username/follow' do
  # Adds the current user as follower of the given user.
  halt 401 unless @user
  username = params['username']
  whom_id = get_user_id(username)
  halt 404 if whom_id.nil?
  @db.execute('insert into follower (who_id, whom_id) values (?, ?)', [session['user_id'], whom_id])
  @db.commit if @db.respond_to?(:commit)
  flash "You are now following \"#{username}\""
  redirect to(url("/#{username}"))
end

get '/:username/unfollow' do
  # Removes the current user as follower of the given user.
  halt 401 unless @user
  username = params['username']
  whom_id = get_user_id(username)
  halt 404 if whom_id.nil?
  @db.execute('delete from follower where who_id=? and whom_id=?', [session['user_id'], whom_id])
  @db.commit if @db.respond_to?(:commit)
  flash "You are no longer following \"#{username}\""
  redirect to(url("/#{username}"))
end

post '/add_message' do
  # Registers a new message for the user.
  halt 401 unless session.key?('user_id')
  if params['text'] && !params['text'].empty?
    @db.execute(%{
      insert into message (author_id, text, pub_date, flagged)
      values (?, ?, ?, 0)
    }, [session['user_id'], params['text'], Time.now.to_i])
    @db.commit if @db.respond_to?(:commit)
    flash 'Your message was recorded'
  end
  redirect to(url('/'))
end

['/login'].each do |path|
  get path do
    # Logs the user in.
    if @user
      redirect to(url('/'))
    end
    error = nil
    erb :login, :locals => { :error => error }
  end

  post path do
    # Logs the user in.
    if @user
      redirect to(url('/'))
    end
    error = nil
    user = query_db(%{
            select * from user where
            username = ?
        }, [params['username']], true)
    if user.nil?
      error = 'Invalid username'
    elsif !BCrypt::Password.new(user['pw_hash']).is_password?(params['password'])
      error = 'Invalid password'
    else
      flash 'You were logged in'
      session['user_id'] = user['user_id']
      redirect to(url('/'))
    end
    erb :login, :locals => { :error => error }
  end
end

['/register'].each do |path|
  get path do
    # Registers the user.
    if @user
      redirect to(url('/'))
    end
    error = nil
    erb :register, :locals => { :error => error }
  end

  post path do
    # Registers the user.
    if @user
      redirect to(url('/'))
    end
    error = nil
    if !params['username'] || params['username'].empty?
      error = 'You have to enter a username'
    elsif !params['email'] || (!params['email'].include?('@'))
      error = 'You have to enter a valid email address'
    elsif !params['password'] || params['password'].empty?
      error = 'You have to enter a password'
    elsif params['password'] != params['password2']
      error = 'The two passwords do not match'
    elsif !get_user_id(params['username']).nil?
      error = 'The username is already taken'
    else
      pw_hash = BCrypt::Password.create(params['password'])
      @db.execute(%{
                insert into user (
                    username, email, pw_hash) values (?, ?, ?)
              }, [params['username'], params['email'], pw_hash])
      @db.commit if @db.respond_to?(:commit)
      flash 'You were successfully registered and can login now'
      redirect to(url('/login'))
    end
    erb :register, :locals => { :error => error }
  end
end

get '/logout' do
  # Logs the user out
  flash 'You were logged out'
  session.delete('user_id')
  redirect to(url('/public'))
end

# add some filters to jinja and set the secret key and debug mode
# from the configuration.
#
# In Sinatra we set helpers for the filters. We add the following helper methods:
helpers do
  def datetimeformat(timestamp)
    format_datetime(timestamp)
  end

  def gravatar(email, size=80)
    gravatar_url(email, size)
  end
end

# Start the application if this file is run directly.
run! if __FILE__ == $0
