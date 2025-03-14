module AuthHelper
  # Check API authorization
  def authenticate_api_request
    auth = request.env['HTTP_AUTHORIZATION']
    return unless auth != 'Basic c2ltdWxhdG9yOnN1cGVyX3NhZmUh'

    halt 403, JSON.generate({ status: 403, error_msg: 'You are not authorized to use this resource!' })
  end

  def current_user
    @current_user ||= session[:user_id] ? get_user_by_id(session[:user_id]) : nil
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
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
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

  # Authenticate user
  def authenticate_user(username, password)
    user = get_user_by_username(username)

    if user.nil?
      { success: false, error: 'Invalid username' }
    elsif BCrypt::Password.new(user[:pw_hash]) != password
      { success: false, error: 'Invalid password' }
    else
      session[:user_id] = user[:user_id] # Store user ID in session
      { success: true, user: user }
    end
  end
end
