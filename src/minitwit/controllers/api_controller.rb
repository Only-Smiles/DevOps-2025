
# ApiController
class ApiController < BaseController
  LATEST = '../tmp/latest_processed_sim_action_id.txt'

  before do
    content_type :json
    parse_api_request
    authenticate_api_request
  end

  after do
    update_latest
    close_db
  end

  # Latest action
  get '/api/latest' do
    file_path = File.join(File.dirname(__FILE__), LATEST)

    latest_processed_command_id = -1
    if File.exist?(file_path)
      begin
        file_content = File.read(file_path).strip
        latest_processed_command_id = Integer(file_content)
      rescue ArgumentError
        latest_processed_command_id = -1
      end
    end

    status 200
    JSON.generate({ 'latest' => latest_processed_command_id })
  end

  # Register user
  post '/api/register' do
    username = @data['username']
    email = @data['email']
    password = @data['pwd']

    result = register_user(username, email, password)

    if result[:success]
      status 204
    else
      status 400
      JSON.generate({ status: 400, error: result[:error].gsub(/\s+/, ''), message: result[:error] })
    end
  end

  # Creates a message given a user
  post '/api/msgs/:username' do
    username = params[:username]
    user_id = get_user_id(username)
    halt 404, 'User not found' unless user_id

    message = @data['content']
    halt 400, "Can't post an empty tweet" unless message

    add_message(user_id, message)
    status 204
  end

  # Get all messages given a username
  get '/api/msgs/:username' do
    no_messages = params[:no] || 100

    username = params[:username]
    user_id = get_user_id(username)
    halt 404 unless user_id

    messages = get_user_messages(user_id, no_messages)
    formatted_messages = format_messages_for_api(messages)

    status 200
    formatted_messages.to_json
  end

  # Get all messages
  get '/api/msgs' do
    no_messages = params[:no] || 100

    messages = get_public_messages(no_messages)
    formatted_messages = format_messages_for_api(messages)

    status 200
    formatted_messages.to_json
  end

  # Follow and unfollow a user
  post '/api/fllws/:username' do
    who_username = params[:username]
    who_id = get_user_id(who_username)
    halt 404 unless who_id

    whom_username = @data['follow'] || @data['unfollow']
    whom_id = get_user_id(whom_username)
    halt 404 unless whom_id

    if @data.key?('unfollow')
      unfollow_user(who_id, whom_id)
      status 204
    elsif @data.key?('follow')
      follow_user(who_id, whom_id)
      status 204
    end
  end

  # Get followers of a user
  get '/api/fllws/:username' do
    no_followers = params[:no] || 100
    username = params[:username]
    id = get_user_id(username)

    halt 404 unless id

    followers = get_followers(id, no_followers)

    status 200
    JSON.generate({ follows: followers })
  end

  # Parse API request body
  def parse_api_request
    @latest = params[:latest]
    body_content = request.body.read.strip
    @data = body_content.empty? ? {} : JSON.parse(body_content)
  rescue JSON::ParserError
    halt 401, JSON.generate({ error: 'InvalidJSON', message: 'Invalid JSON format' })
  end

  # Update latest processed action ID
  def update_latest
    return if @latest.nil?

    file_path = File.join(File.dirname(__FILE__), LATEST)
    File.write(file_path, @latest)
  end
end
