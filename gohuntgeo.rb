require "sinatra"
require "rack-flash"
require "gschool_database_connection"
require "simple_geolocation"
require "pony"

class GoHuntGeoApp < Sinatra::Base
  enable :sessions
  use Rack::Flash


  def initialize
    super
    @database_connection = GschoolDatabaseConnection::DatabaseConnection.establish(ENV["RACK_ENV"])
  end

  get '/' do
    erb :root
  end

  post "/" do
    username = params[:username]
    password = params[:password]
    if username == "" && password == ""
      flash[:notice] = "No username or password entered"
      redirect '/login'
    elsif password == ""
      flash[:notice] = "No password entered"
      redirect '/login'
    elsif username == ""
      flash[:notice] = "No username entered"
      redirect '/login'
    elsif @database_connection.sql("SELECT username, password from users where username = '#{username}' and password = '#{password}'") == []
      flash[:notice] = "Incorrect Username and Password"
      redirect '/login'
    else
      user_id_hash = session[:user] = @database_connection.sql("Select id from users where username = '#{username}'").reduce
      session[:user] = user_id_hash["id"]
      redirect '/user_page'
      @list_users = @database_connection.sql("Select username from users")
      erb :login, :locals => {:username => username}
    end
  end

  get '/login' do
    erb :login
  end

  get '/register' do
    erb :register
  end

  post "/register" do
    username = params[:username]
    password = params[:password]
    if username == "" && password == ""
      flash[:notice] = "No username or password entered"
    elsif password == ""
      flash[:notice] = "No password entered"
    elsif username == ""
      flash[:notice] = "No username entered"
    else
      if @database_connection.sql("SELECT username from users where username = '#{username}'") == []
        @database_connection.sql("INSERT INTO users (username, password) values ('#{username}', '#{password}')")
        user_id_hash = session[:user] = @database_connection.sql("Select id from users where username = '#{username}'").reduce
        session[:user] = user_id_hash["id"]
        flash[:notice] = "Thank you for registering"
        redirect '/user_page'
      else
        flash[:notice] = "Username already taken"
        redirect back
      end
    end
    redirect back
  end

  get '/user_page' do
    erb :user_page
  end

  post '/user_page' do
    x_forwarded_ip = request.env['HTTP_X_FORWARDED_FOR']
    ip = request.env['REMOTE_ADDR']
    if get_my_location(ip).nil?
      ip = '74.125.113.104'
    end
    remote_ip_location = get_my_location(ip)
    if x_forwarded_ip.present?
      @location = get_my_location(x_forwarded_ip.split(',')[0])
      if @location.nil?
        @location = remote_ip_location
      end
    else
      @location = remote_ip_location
    end
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

  post '/contact_us' do
    name = params[:name]
    email = params[:email]
    message = params[:message]
    Pony.mail :to => 'cameron.p.buckingham@gmail.com',
              :from => 'GoHuntGeo',
              :subject => 'Message from GoHuntGeo',
              :body => erb(:email, :locals => {name: name, email: email, message: message}, layout:false)
    flash[:notice] = "Thanks for your message, we'll get back to you shortly"
    redirect '/contact_us'
end

  run! if app_file == $0

  def get_my_location(ip)
    SimpleGeolocation::Geocoder.new(ip).geocode!
  end
end

