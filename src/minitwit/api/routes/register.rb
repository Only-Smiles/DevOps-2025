require 'sinatra'
require 'json'
require 'bcrypt'

class MiniTwit < Sinatra::Base

  post '/api/register' do
    content_type :json

    # Parse the JSON body
    begin
      @data = JSON.parse(request.body.read)
    rescue JSON::ParserError
      status 400
      return body JSON({ 'error': "InvalidJSON", 'message': "Request body must be valid JSON" })
    end

    @username = @data['username']
    @email = @data['email']
    password = @data['pwd']
  
    if @username.nil? || @username.empty?
      status 400
      body JSON({ 'error': "MissingUsername", 'message': "You have to enter a username" })
    elsif @email.nil? || @email.empty? || !@email.include?('@')
      status 400
      body JSON({ 'error': "MissingEmail", 'message': "You have to enter a valid email address" })
    elsif password.nil? || password.empty?
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