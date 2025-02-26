require 'sinatra'

class MiniTwit < Sinatra::Base

  post '/api/fllws/:username' do
    content_type :json

    begin
      @data = JSON.parse(request.body.read)
    rescue JSON::ParserError
      status 400
      return body JSON({ 'error': "InvalidJSON", 'message': "Request body must be valid JSON" })
    end
    
    req = req_from_sim(request)
    return req unless req.nil?

    # halt 401, "Unauthorized" unless @user

    who_username = params[:username]
    who_id = get_user_id(who_username)
    halt 404, who_username + " was not found" unless !who_id.nil?

    whom_username = @data['follow'] || @data['unfollow']
    whom_id = get_user_id(whom_username)
    halt 404, whom_username + " was not found" unless !whom_id.nil?
    
    
    if @data.key?('unfollow')
      query_db('DELETE FROM follower WHERE who_id = ? AND whom_id = ?', [who_id, whom_id])
      status 200
      body JSON({ 'message': 'Unfollowed ' + whom_username })
    elsif @data.key?('follow')
      query_db('INSERT INTO follower (who_id, whom_id) VALUES (?, ?)', [who_id, whom_id])
      status 200
      body JSON({ 'message': 'Followed ' + whom_username,  })
    end
  end


  get '/api/fllws/:username' do
    req = req_from_sim(request)
    return req unless req.nil?

    no_followers = params[:no] || 100
    username = params[:username]
    id = get_user_id(username)

    followers = query_db('SELECT u.username FROM user u
            INNER JOIN follower f on f.whom_id=u.user_id
            WHERE f.who_id = ?
            LIMIT ?', [id, no_followers])
    follower_names = followers.map{|x| x['username']}
    status 200
    body JSON({'follows': follower_names})
  end 

end
