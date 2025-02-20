require 'sinatra'

class MiniTwit < Sinatra::Base

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

end
