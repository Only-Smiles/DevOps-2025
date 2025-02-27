class BaseController < Sinatra::Base

  configure do
    set :views, 'views'
    set :public_folder, 'public'
  end

  include DbHelper
  include AuthHelper
  include FormatHelper
end