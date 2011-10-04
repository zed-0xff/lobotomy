require 'nanoc3/tasks'

task :default => :compile

desc "compile site"
task :compile do
  require 'nanoc3/cli'
  Nanoc3::CLI.run ["compile"]
end

namespace :gems do
  desc "install required gems"
  task :install do
    system "gem install nanoc3 RedCloth coderay systemu"
  end
end

desc "run a local server"
task :server => :compile do
  require 'nanoc3/cli'
  Nanoc3::CLI.run ["view"]
end

desc "deploy to server"
task :deploy => :compile do
#  system "scp -r output/* zed.0xff.me:/apps/lobotomy/"
  system "rsync -avz output/ lobotomy.me:/vz/private-names/web/var/www/lobotomy.me"
end

namespace :posts do
  desc "Create a new blog post"
  task :new do
    require 'yaml'

    title = ENV['title'] ||
      begin
        print "Post title: "
        $stdin.gets.chomp.strip
      end

    format = ENV['format'] ||
      begin
        print "Post format (md,textile,html,erb) (default: md) : "
        $stdin.gets.chomp.strip
      end

    date = ENV['date'] ? Time.parse(ENV['date']) : Time.now

    format.strip!
    format = 'md' if format.empty?
    name = title.gsub(/\s+/, '-')
    name = name.gsub(/[^a-zA-Z0-9_-]/, "").downcase
    time = date.strftime("%Y-%m-%d")
    fname = "content/#{time}-#{name}.#{format}"
    raise "#{fname} already exists!" if File.exist?(fname)
    File.open(fname, "w+") do |file|
      file.puts({'title' => title, 'author' => ENV['USER']}.to_yaml + "---")
    end
    puts "Created #{fname}"
    system ENV['EDITOR'], fname
  end
end

task :sass do
  infile = "_sass/site.scss"
  outfile = "content/resource/site.css"
  data = '@charset "UTF-8";'
  data << `sass --scss #{infile} --style compressed`
  data.gsub!(' px','px ') # fix weird sass bug
  File.open(outfile,'w'){ |f| f << data }
end
