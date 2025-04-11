module AuthHelper
  # Redis key prefix for user sessions
  USER_SESSION_PREFIX = 'user_session:'
  USER_SESSION_TTL = 86400 # 1 day in seconds

  # Check API authorization
  def authenticate_api_request
    auth = request.env['HTTP_AUTHORIZATION']
    return unless auth != 'Basic c2ltdWxhdG9yOnN1cGVyX3NhZmUh'

    halt 403, JSON.generate({ status: 403, error_msg: 'You are not authorized to use this resource!' })
  end

  def current_user
    # First try to get user from session
    session_user_id = session[:user_id]
    return nil unless session_user_id

    # Check if user data is cached in Redis
    redis_key = "#{USER_SESSION_PREFIX}#{session_user_id}"
    cached_user = cache_get(redis_key)
    
    if cached_user
      # Extend the TTL of the cached user data
      cache_set(redis_key, cached_user, USER_SESSION_TTL)
      return cached_user
    end

    # If not cached, fetch from database and cache it
    user = get_user_by_id(session_user_id)
    if user
      cache_set(redis_key, user, USER_SESSION_TTL)
      return user
    end

    # If user not found, clear session
    session.delete(:user_id)
    nil
  end

  # Register user
  def register_user(username, email, password)
    return { success: false, error: 'You have to enter a username' } if username.nil? || username.empty?

    if email.nil? || email.empty? || !email.include?('@')
      return { success: false,
               error: 'You have to enter a valid email address' }
    end
    return { success: false, error: 'You have to enter a password' } if password.nil? || password.empty?

    existing_user = get_user_by_username(username)
    return { success: false, error: 'Username is already taken.' } if existing_user

    password_hash = BCrypt::Password.create(password)

    # Using Sequel to insert the new user
    db[:user].insert(
      username: username,
      email: email,
      pw_hash: password_hash
    )

    { success: true }
  end

  # Authenticate user
  def authenticate_user(username, password)
    user = get_user_by_username(username)

    if user.nil?
      { success: false, error: 'Invalid username' }
    elsif BCrypt::Password.new(user[:pw_hash]) != password
      { success: false, error: 'Invalid password' }
    else
      # Store user ID in session
      session[:user_id] = user[:user_id]
      
      # Cache user data in Redis for cross-VM access
      redis_key = "#{USER_SESSION_PREFIX}#{user[:user_id]}"
      cache_set(redis_key, user, USER_SESSION_TTL)
      
      { success: true, user: user }
    end
  end

  # Logout user
  def logout_user
    if session[:user_id]
      # Remove Redis cached user data
      redis_key = "#{USER_SESSION_PREFIX}#{session[:user_id]}"
      cache_delete(redis_key)
    end
    
    # Clear session
    session.clear
  end
end
