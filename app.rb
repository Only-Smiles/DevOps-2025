#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# MiniTwit
# ~~~~~~~~
#
# A microblogging application written with Flask and sqlite3.
#
# :copyright: (c) 2010 by Armin Ronacher.
# :license: BSD, see LICENSE for more details.

require 'sinatra'
require 'sinatra/flash'
require 'sqlite3'
require 'digest/md5'
require 'time'
require 'date'
require 'bcrypt'
require 'fileutils'

# configuration
DATABASE = './tmp/minitwit.db'
PER_PAGE = 30
DEBUG = true
SECRET_KEY = 'development key'

# create our little application :)
configure do
  enable :sessions
  set :session_secret, SECRET_KEY
  set :port, 8080
  set :bind, '0.0.0.0'
  set :logging, DEBUG
end

# # Ensure tmp directory exists for the database
# FileUtils.mkdir_p(File.dirname(DATABASE))

helpers do
  # Format a timestamp for display.
  def format_datetime(timestamp)
    Time.at(timestamp).utc.strftime('%Y-%m-%d @ %H:%M')
  end

  # Return the gravatar image for the given email address.
  def gravatar_url(email, size=80)
    hash = Digest::MD5.hexdigest(email.strip.downcase.encode('utf-8'))
    "http://www.gravatar.com/avatar/#{hash}?d=identicon&s=#{size}"
  end
end

def connect_db
  # Returns a new connection to the database.
  db = SQLite3::Database.new(DATABASE)
  db.results_as_hash = true
  return db
end

def init_db
  # Creates the database tables.
  db = connect_db
  schema_path = File.join(settings.root, 'schema.sql')
  File.open(schema_path, 'r') do |f|
    # SQLite3::Database#execute_batch executes multiple SQL statements
    db.execute_batch(f.read)
  end
  db.close
end

def query_db(query, args=[], one=false)
  # Queries the database and returns a list of dictionaries.
  cur = settings.db.execute(query, args)
  rv = cur.map do |row|
    # Each row is already a hash because results_as_hash is set.
    row
  end
  return one ? (rv.empty? ? nil : rv[0]) : rv
end

def get_user_id(username)
  # Convenience method to look up the id for a username.
  rv = settings.db.get_first_row('select user_id from user where username = ?', [username])
  return rv ? rv['user_id'] : nil
end

# Before each request, connect to the database and look up the current user.
before do
  # Make sure we are connected to the database each request and look
  # up the current user so that we know he's there.
  @db = connect_db
  settings.db = @db
  @user = nil
  if session.key?('user_id')
    @user = query_db('select * from user where user_id = ?', [session['user_id']], true)
  end
end

# After each request, close the database connection.
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
  messages = query_db(<<-SQL, [session['user_id'], session['user_id'], PER_PAGE])
        select message.*, user.* from message, user
        where message.flagged = 0 and message.author_id = user.user_id and (
            user.user_id = ? or
            user.user_id in (select whom_id from follower
                                    where who_id = ?))
        order by message.pub_date desc limit ?
  SQL
  erb :timeline, locals: { messages: messages }
end

get '/public' do
  # Displays the latest messages of all users.
  messages = query_db(<<-SQL, [PER_PAGE])
        select message.*, user.* from message, user
        where message.flagged = 0 and message.author_id = user.user_id
        order by message.pub_date desc limit ?
  SQL
  erb :timeline, locals: { messages: messages }
end

get '/:username' do |username|
  # Display's a users tweets.
  profile_user = query_db('select * from user where username = ?', [username], true)
  halt 404 if profile_user.nil?
  followed = false
  if @user
    followed = (query_db(<<-SQL, [session['user_id'], profile_user['user_id']], true) != nil)
      select 1 from follower where
            follower.who_id = ? and follower.whom_id = ?
    SQL
  end
  messages = query_db(<<-SQL, [profile_user['user_id'], PER_PAGE])
            select message.*, user.* from message, user where
            user.user_id = message.author_id and user.user_id = ?
            order by message.pub_date desc limit ?
  SQL
  erb :timeline, locals: { messages: messages, followed: followed, profile_user: profile_user }
end

get '/:username/follow' do |username|
  # Adds the current user as follower of the given user.
  halt 401 unless @user
  whom_id = get_user_id(username)
  halt 404 if whom_id.nil?
  @db.execute('insert into follower (who_id, whom_id) values (?, ?)', [session['user_id'], whom_id])
  @db.execute('commit')
  flash "You are now following \"#{username}\""
  redirect to(url("/#{username}"))
end

get '/:username/unfollow' do |username|
  # Removes the current user as follower of the given user.
  halt 401 unless @user
  whom_id = get_user_id(username)
  halt 404 if whom_id.nil?
  @db.execute('delete from follower where who_id=? and whom_id=?', [session['user_id'], whom_id])
  @db.execute('commit')
  flash "You are no longer following \"#{username}\""
  redirect to(url("/#{username}"))
end

post '/add_message' do
  # Registers a new message for the user.
  halt 401 unless session.key?('user_id')
  if params['text'] && !params['text'].empty?
    @db.execute(<<-SQL, session['user_id'], params['text'], Time.now.to_i)
      insert into message (author_id, text, pub_date, flagged)
            values (?, ?, ?, 0)
    SQL
    @db.execute('commit')
    flash 'Your message was recorded'
  end
  redirect to(url('/'))
end

get '/login' do
  # Logs the user in.
  if @user
    redirect to(url('/'))
  end
  erb :login, locals: { error: nil }
end

post '/login' do
  # Logs the user in.
  if @user
    redirect to(url('/'))
  end
  error = nil
  user = query_db(<<-SQL, [params['username']], true)
            select * from user where
            username = ?
  SQL
  if user.nil?
    error = 'Invalid username'
  elsif !BCrypt::Password.new(user['pw_hash']).is_password?(params['password'])
    error = 'Invalid password'
  else
    flash 'You were logged in'
    session['user_id'] = user['user_id']
    redirect to(url('/'))
  end
  erb :login, locals: { error: error }
end

get '/register' do
  # Registers the user.
  if @user
    redirect to(url('/'))
  end
  erb :register, locals: { error: nil }
end

post '/register' do
  # Registers the user.
  if @user
    redirect to(url('/'))
  end
  error = nil
  if !params['username'] || params['username'].empty?
    error = 'You have to enter a username'
  elsif !params['email'] || params['email'].index('@').nil?
    error = 'You have to enter a valid email address'
  elsif !params['password'] || params['password'].empty?
    error = 'You have to enter a password'
  elsif params['password'] != params['password2']
    error = 'The two passwords do not match'
  elsif get_user_id(params['username'])
    error = 'The username is already taken'
  else
    pw_hash = BCrypt::Password.create(params['password'])
    @db.execute(<<-SQL, params['username'], params['email'], pw_hash)
      insert into user (
                username, email, pw_hash) values (?, ?, ?)
    SQL
    @db.execute('commit')
    flash 'You were successfully registered and can login now'
    redirect to(url('/login'))
  end
  erb :register, locals: { error: error }
end

get '/logout' do
  # Logs the user out
  flash 'You were logged out'
  session.delete('user_id')
  redirect to(url('/public'))
end

# add some filters to jinja and set the secret key and debug mode
# from the configuration.
# In Sinatra, we add helper methods and use the settings for configuration.
# The helpers "format_datetime" and "gravatar_url" serve as our filters.

# start the application if ruby file executed directly
#run! if __FILE__ == $0
