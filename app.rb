require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sqlite3'

def get_db
  db = SQLite3::Database.new 'barber_shop.sqlite'
  db.results_as_hash = true
  return db
end

configure do
  db = get_db
  db.execute 'CREATE TABLE IF NOT EXISTS "Users" (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "username" TEXT,
    "phone" TEXT,
    "datestamp" TEXT,
    "barber" TEXT,
    "color" TEXT
  )'
end

configure do
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Hello stranger'
  end
end

before '/secure/*' do
  unless session[:identity]
    session[:previous_url] = request.path
    @error = 'Sorry, you need to be logged in to visit ' + request.path
    halt erb(:login_form)
  end
end

get '/' do
  erb 'Can you handle a <a href="/secure/place">secret</a>?'
end

get '/login/form' do
  erb :login_form
end

post '/login/attempt' do
  session[:identity] = params['username']
  where_user_came_from = session[:previous_url] || '/'
  redirect to where_user_came_from
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/secure/place' do
  erb 'This is a secret place that only <%=session[:identity]%> has access to!'
end

get '/about' do
  @error = 'something wrong'
  erb :about
end

get '/visit' do
  erb :visit
end

get '/contacts' do
  erb :contacts
end

post '/visit' do
  @username = params[:username]
  @phone = params[:phone]
  @datetime = params[:datetime]
  @barber = params[:barber]
  @color = params[:color]

  input_info = {
    username: 'Enter name',
    phone: 'Enter phone',
    datetime: 'Enter date and time'
  }

  @error = input_info.select { |key, _| params[key] == '' }.values.join(', ')
  return erb :visit if @error != ''

  db = get_db
  db.execute 'insert into Users (
    username,
    phone,
    datestamp,
    barber,
    color
  ) values (?, ?, ?, ?, ?)', [
    @username,
    @phone,
    @datetime,
    @barber,
    @color
  ]

  erb "#{@username} #{@phone} #{@datetime} #{@barber} #{@color}"
end

get '/showusers' do
  erb 'Hello world'
end
