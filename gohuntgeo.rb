require 'sinatra'

class GoHuntGeoApp < Sinatra::Base

  get '/' do
    erb :root
  end
  get '/login_sign_up' do
    erb :login_sign_up
  end
  get '/user_page' do
    erb :user_page
  end
  get '/how_to_start' do
    erb :how_to_start
  end
  get '/how_this_works' do
    erb :how_this_works
  end
  get '/why' do
    erb :why
  end
  get '/contact_us' do
    erb :contact_us
  end

  run! if app_file == $0
end

