require 'sinatra'

class MiniTwit < Sinatra::Base

  post '/msgs/:username' do
    req = req_from_sim(request)
    return req unless req.nil?

    username = params[:username]
    user_id = get_user_id(username)
    halt 404, "User not found" unless !user_id.nil?

    message = @data["content"]
    halt 400, "Can't post an empty tweet" unless !message.nil?

    query_db('INSERT INTO message (author_id, text, pub_date, flagged) VALUES (?, ?, ?, 0)',
      [user_id, message, Time.now.to_i])
    status 204
  end


  get '/msgs/:username' do
    req = req_from_sim(request)
    return req unless req.nil?

    no_messages = params[:no] || 100

    username = params[:username]
    user_id = get_user_id(username)
    halt 404, "user " + username + " not found" unless !user_id.nil?

    query = "SELECT message.*, user.* FROM message, user
                   WHERE message.flagged = 0 AND
                   user.user_id = message.author_id AND user.user_id = ?
                   ORDER BY message.pub_date DESC LIMIT ?"
    messages = query_db(query, [user_id, no_messages])

    filtered_msgs = []
    for msg in messages
      filtered_msgs.append({
        "content" => msg["text"],
        "pub_date" => msg["pub_date"],
        "user" => msg["username"]
      })
    end

    status 200
    body filtered_msgs.to_json()
  end


  get '/msgs' do
    req = req_from_sim(request)
    return req unless req.nil?

    no_messages = params[:no] || 100

    query = "SELECT message.*, user.* FROM message, user
        WHERE message.flagged = 0 AND message.author_id = user.user_id
        ORDER BY message.pub_date DESC LIMIT ?"
    messages = query_db(query, [no_messages])

    filtered_msgs = []
    for msg in messages do
      filtered_msgs.append({
        "content" => msg["text"],
        "pub_date" => msg["pub_date"],
        "user" => msg["username"]
      })
    end

    status 200
    body filtered_msgs.to_json()
  end

end

