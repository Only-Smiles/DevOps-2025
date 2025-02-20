require 'sinatra'

class MiniTwit < Sinatra::Base

  post '/add_message' do
    halt 401 unless @user
    if params[:text] && !params[:text].empty?
      query_db('INSERT INTO message (author_id, text, pub_date, flagged) VALUES (?, ?, ?, 0)',
        [@user['user_id'], params[:text], Time.now.to_i])

      # flash[:notice] = "Your message was recorded"
      redirect '/'
    end
  end

end

