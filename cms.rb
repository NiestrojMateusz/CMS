require "sinatra"
require "sinatra/reloader"
require "erubis"

get "/" do
  @files = Dir["data/*"].map do |path|
    File.basename(path)
  end

  erb :index
end
