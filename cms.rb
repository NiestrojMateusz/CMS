require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "pry"
require "redcarpet"
root = File.expand_path(".." ,__FILE__) 

configure do
  enable :sessions # tells sinatra to enable a sessions support
  set :session_secret, 'secret' # setting session secret, for production this should be something longer and not straightforward in the code
end

def markdown_render(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

get "/" do
  @files = Dir["data/*"].map do |path|
    File.basename(path)
  end

   erb :index
end

get "/:filename" do
  file_path = root + "/data/" + params[:filename]
  if File.file?(file_path)

    if File.extname(file_path) == ".md"
      markdown_render(File.read(file_path))
    else
      headers["Content-Type"] = "text/plain"
      File.read(file_path)
    end
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end

end
