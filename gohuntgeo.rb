require "sinatra"
require "rack-flash"
require "gschool_database_connection"

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
    elsif password == ""
      flash[:notice] = "No password entered"
    elsif username == ""
      flash[:notice] = "No username entered"
    elsif @database_connection.sql("SELECT username, password from users where username = '#{username}' and password = '#{password}'") == []
      flash[:notice] = "Incorrect Username and Password"
    else
      user_id_hash = session[:user] = @database_connection.sql("Select id from users where username = '#{username}'").reduce
      user_id = user_id_hash["id"]
      session[:user] = user_id
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
    p
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

