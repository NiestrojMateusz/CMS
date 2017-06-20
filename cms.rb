require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "pry"
require "redcarpet"
require "pry-remote"
require "yaml"
require "bcrypt"

configure do
  enable :sessions # tells sinatra to enable a sessions support
  set :session_secret, 'secret' # setting session secret, for production this should be something longer and not straightforward in the code
end

def markdown_render(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def user_sign_in?
  session.key?(:username)  
end

def required_sign_in
 if !user_sign_in? 
   session[:message] = "You must be signed in to do that."
   redirect "/"
 end
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/users.yml", __FILE__)
  else
    File.expand_path("../users.yml", __FILE__)
  end
  YAML.load_file(credentials_path)
end

def valid_credentials?(username, password)
  credentials = load_user_credentials

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == password
  else
    false
  end
end

get "/" do
  pattern = File.join(data_path, "*")
  @files =Dir.glob(pattern).map do |path|
    File.basename(path)
  end

   erb :index, layout: :layout
end

# Display view for creating new file
get "/new" do
  required_sign_in
  erb :new, layout: :layout
end

# Create new file
post "/create" do
  required_sign_in
  filename = params[:new_document].to_s

  if filename.size == 0 
    session[:message] = "The file name is required"
    status 422
    erb :new
  else 
    file_path = File.join(data_path, filename)

    session[:message] = "#{filename} has been created."

    File.write(file_path, "")
    redirect "/"
  end
end


get "/:filename" do
  file_path = File.join(data_path, params[:filename])
  if File.file?(file_path)

    if File.extname(file_path) == ".md"
      erb markdown_render(File.read(file_path))
    elsif File.extname(file_path) == ".txt"
      headers["Content-Type"] = "text/plain"
      File.read(file_path)
    end

  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

get "/:filename/edit" do
  required_sign_in
  file_path = File.join(data_path, params[:filename])
  @file_content = File.read(file_path)
  erb :edit
end

post "/:filename" do
  required_sign_in
  file_path = File.join(data_path, params[:filename])
  File.write(file_path, params[:content])
  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end

# Delete file
post "/:filename/delete" do
  required_sign_in
  filename = params[:filename].to_s
  file_path = File.join(data_path, params[:filename])
  File.delete(file_path)
  session[:message] = "#{filename} has been deleted"
  redirect "/"
end

get "/users/signin" do
  erb :signin
end

post "/users/signin" do
  username = params[:username]
  
  if valid_credentials?(username, params[:password]) 
    session[:username] = username 
    session[:message] = 'Welcome!'
    redirect "/"
  else
    session[:message] = "Invalid credentials"
    status 422
    erb :signin
  end

 end

post "/users/signout" do
  session.delete(:username)
  session[:message] = "You have been signed out."
  redirect "/"
end

