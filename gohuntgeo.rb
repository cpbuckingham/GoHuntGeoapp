require "sinatra"
require "rack-flash"
require "gschool_database_connection"
require "simple_geolocation"
require "pony"
require "sass"

class GoHuntGeoApp < Sinatra::Base
  configure do
    Pony.options = {
      :via => :smtp,
      :via_options => {
        :address => 'smtp.sendgrid.net',
        :port => '587',
        :domain => 'http://dry-retreat-1477.herokuapp.com/refer',
        :user_name => ENV['SENDGRID_USERNAME'],
        :password => ENV['SENDGRID_PASSWORD'],
        :authentication => :plain,
        :enable_starttls_auto => true
      }
    }
  end
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

      user_id_hash = @database_connection.sql("Select id from users where username = '#{username}'").reduce
      session[:user] = user_id_hash["id"].to_i
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
        @database_connection.sql("INSERT INTO users (username, password, count) values ('#{username}', '#{password}', 0)")
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
    @states = @database_connection.sql("SELECT abbreviation FROM States")
    @id = @database_connection.sql("select username from users where id = #{session[:user]}")
    @total = @database_connection.sql("select count from users where id = #{session[:user]}").pop["count"]
    if @database_connection.sql("select state_id from states_visited where user_id = #{session[:user]}") == []
    then
      erb :user_page
    else
      @user_states = @database_connection.sql("select state_id from states_visited where user_id = #{session[:user]}").map { |x| x["state_id"].to_i }
      @states_expense =@database_connection.sql("select state_id from states_expense where user_id = #{session[:user]}").map { |x| x["state_id"].to_i }
      @user_states_visited = []
      @user_states_expense = []

      @states_expense.each do |state_id|
        ids = @database_connection.sql("select abbreviation from states where id = #{state_id}").first["abbreviation"].downcase
        @user_states_expense.push ids
      end
      @user_states.each do |state_id|
        ids = @database_connection.sql("select abbreviation from states where id = #{state_id}").first["abbreviation"].downcase
        @user_states_visited.push ids
        p @user_states_visited
      end
    end

    erb :user_page
  end

  post '/user_page' do
    redirect '/login?' unless session[:user]
    x_forwarded_ip = request.env['HTTP_X_FORWARDED_FOR']
    ip = request.env['REMOTE_ADDR']
    if get_my_location(ip).nil?
      ip = '50.201.187.132'#CO
      # ip = '74.125.113.104' #CA
    end
    remote_ip_location = get_my_location(ip)
    if x_forwarded_ip.present?
      @location = get_my_location(x_forwarded_ip.split(', ')[0])
      if @location.nil?
        @location = remote_ip_location
      end
    else
      @location = remote_ip_location
    end

      flash[:notice]= "Thanks for visiting #{@location.state}"

      state_id = @database_connection.sql("Select id from states where abbreviation = '#{@location.state}'").first["id"]
      user_id = session[:user].to_i

      visited = @database_connection.sql("select count(*) as visited from states_visited where user_id = #{user_id} and state_id = #{state_id}").pop["visited"]
      if visited.to_i == 0
        state_point_value = @database_connection.sql("select value from states where id = (#{state_id})").pop["value"]
        current_user_points = @database_connection.sql("select count from users where id = #{user_id}").pop["count"]
        current_user_total_points = current_user_points.to_i + state_point_value.to_i
        @database_connection.sql("update users set count = #{current_user_total_points} where id = #{user_id}")
        @database_connection.sql("Insert into states_visited (user_id, state_id) values (#{user_id}, #{state_id})")
      else
        flash[:notice]="You already got points for visiting #{@location.state}"
        redirect back
      end
      @total = @database_connection.sql("select count from users where id = #{user_id}").pop["count"]

    redirect '/user_page'
  end

  get '/how_this_works' do
    erb :how_this_works
  end
  get '/expense' do
    erb :expense
  end

  post '/expense' do
    redirect '/login?' unless session[:user]
    user_id = session[:user].to_i
    @states = @database_connection.sql("SELECT abbreviation FROM States")
    abbreviations = @states.map { |x| x["abbreviation"]}
    @expense = params[:expense].upcase
    if !abbreviations.include?(@expense)
      flash[:notice] = "This state does not exist"
      redirect '/expense'
    else
      state_id = @database_connection.sql("Select id from states where abbreviation = '#{@expense}'").first["id"]
      @total = @database_connection.sql("select count from users where id = #{user_id}").pop["count"]
      exp = @expense
      costs = @database_connection.sql("select expense from states where abbreviation = '#{exp}'").pop["expense"]
      if costs.to_i > @total.to_i
        flash[:notice] = "You do not have enough points to expense this state"
      else
        total = @total.to_i - costs.to_i
        @database_connection.sql("UPDATE users set count = #{total} where id = #{user_id}")
        @database_connection.sql("Insert into states_expense (user_id, state_id) values (#{user_id}, #{state_id})")
        flash[:notice] = "Thanks for expensing #{@expense}"

        @user_states_expense = @database_connection.sql("select state_id from states_expense where user_id = #{session[:user]}").map { |x| x["state_id"].to_i }
      end
    end
    redirect '/user_page'
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
              :body => erb(:email, :locals => {name: name, email: email, message: message}, layout: false)
    flash[:notice] = "Thanks for your message, we'll get back to you shortly"
    redirect '/contact_us'
  end

  get '/refer' do
    erb :refer
  end

  post '/refer' do
    friend_name = params[:friend_name]
    friend_email = params[:friend_email]
    Pony.mail :to => friend_email,
              :from => 'GoHuntGeo',
              :subject => 'Message from GoHuntGeo',
              :body => erb(:email_2, :locals => {friend_name: friend_name, friend_email: friend_email}, layout: false)
    flash[:notice] = "Thanks for referring a friend, once they register you will earn one point"
    redirect '/user_page'
  end

  run! if app_file == $0

  def get_my_location(ip)
    SimpleGeolocation::Geocoder.new(ip).geocode!
  end
end
