require 'sinatra'

class MiniTwit < Sinatra::Base

  post '/latest' do
    content_type :json
    # Honestly not sure what to do here

    status 200
    body JSON({})
  end

end
