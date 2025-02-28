class BaseController < Sinatra::Base

  configure do
    set :views, 'views'
    set :public_folder, 'public'
  end

  helpers DbHelper
  helpers AuthHelper
  helpers FormatHelper  
end