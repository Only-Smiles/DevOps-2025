class BaseController < Sinatra::Base

  configure do
    set :views, File.join(__dir__, '..', 'views')
    set :public_folder, File.join(__dir__, '..', 'public')
  end
  
  helpers DbHelper
  helpers AuthHelper
  helpers FormatHelper  

end

