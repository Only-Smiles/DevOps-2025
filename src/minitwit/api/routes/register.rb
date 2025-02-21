require 'sinatra'

class MiniTwit < Sinatra::Base

  post '/register' do
    content_type :json

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
      body JSON({ 'error': "MissingPassword", 'message': "You have to enter a password" })
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
end
