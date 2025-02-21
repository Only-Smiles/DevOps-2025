require 'sinatra'

class MiniTwit < Sinatra::Base

  post '/fllws/:username' do 
    content_type :json
    # Left out while testing TODO: Testing does give Authorization token so use that 
    req = req_from_sim(request)
    return req unless req.nil?

    # halt 401, "Unauthorized" unless @user

    who_id = params[:username]
    whom_id = @data['follow'] || @data['unfollow']
    if whom_id.nil? || who_id.nil?
      status 404
      body JSON({ 'message': "Either #{who_id} or #{@data} not found" })
    end
      
    if @data.key?('unfollow')
      query_db('DELETE FROM follower WHERE who_id = ? AND whom_id = ?', [who_id, whom_id])
      status 200
      body JSON({ 'message': 'Unfollowed #{whom_id}' })
    elsif @data.key?('follow')
      query_db('INSERT INTO follower (who_id, whom_id) VALUES (?, ?)', [who_id, whom_id])
      status 200
      body JSON({ 'message': 'Followed #{whom_id}',  })
    end
  end


  get '/fllws/:username' do
    # write request to some txt bc that's who we are apparently (see og)
    # req = req_from_sim(request)
    # return req unless req.nil?

    no_followers = request.env['no'] || 100
    followers = query_db('SELECT u.username FROM user u
            INNER JOIN follower f on f.whom_id=u.username
            WHERE f.who_id = ?
            LIMIT ?', [params[:username], no_followers])
    follower_names = followers.map{|x| x['username']}
    status 200
    body JSON({'follows': follower_names})
  end 

end
