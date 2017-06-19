require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "pry"
require "redcarpet"
require "pry-remote"

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

get "/" do
  pattern = File.join(data_path, "*")
  @files =Dir.glob(pattern).map do |path|
    File.basename(path)
  end

   erb :index, layout: :layout
end

get "/new" do
  erb :new, layout: :layout
end

get "/:filename" do
  file_path = File.join(data_path, params[:filename])
  if File.file?(file_path)

    if File.extname(file_path) == ".md"
      erb markdown_render(File.read(file_path))
    else
      headers["Content-Type"] = "text/plain"
      File.read(file_path)
    end
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

get "/:filename/edit" do
  file_path = File.join(data_path, params[:filename])
  @file_content = File.read(file_path)
  erb :edit
end

post "/:filename" do
  file_path = File.join(data_path, params[:filename])
  File.write(file_path, params[:content])
  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end

