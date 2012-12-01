require 'rubygems'
require 'nanoc3/tasks'

task :default => :compile

desc "compile site"
task :compile do
  require 'nanoc3/cli'
  Nanoc3::CLI.run ["compile"]
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

def new_post type = 'Post', params = {}
  require 'yaml'

  title = ENV['title'] ||
    begin
      print "[.] #{type} title: "
      $stdin.gets.chomp.strip
    end

  format = ENV['format'] ||
    begin
      print "[.] #{type} format (md,textile,html,erb,haml) (default: md) : "
      $stdin.gets.chomp.strip
    end

  date = ENV['date'] ? Time.parse(ENV['date']) : Time.now

  format.strip!
  format = 'md' if format.empty?
  name = title.gsub(/\s+/, '-')
  name = name.gsub(/[^a-zA-Z0-9_-]/, "").downcase
  time = date.strftime("%Y-%m-%d")

  dir = "content/#{time}-#{name}"
  Dir.mkdir(dir) unless Dir.exist?(dir)

  fname = "#{dir}/index.#{format}"
  raise "#{fname} already exists!" if File.exist?(fname)
  File.open(fname, "w+") do |f|
    f << {'title' => title, 'author' => ENV['USER']}.merge(params).to_yaml
    f << "---\n\n"
  end
  puts "[=] Created #{fname}"
  puts "[.] Place this post assets (images, binaries, etc) in #{dir}/"
  fname
end

def launch_editor fname
  editor = ENV['EDITOR']
  case editor
  when nil,''
    puts "[!] no EDITOR env variable set! please edit #{fname} manually"
  when /vim/
    # place cursor on last line in vim
    system editor, fname, "+99"
  else
    system editor, fname
  end
end

namespace :posts do
  desc "Create new post"
  task :new do
    launch_editor new_post
  end

  task :move2dirs do
    require 'fileutils'
    Dir['content/????-??-??-*.*'].each do |fname|
      a = fname.split('.')
      raise unless a.size == 2
      dir,ext = a
      Dir.mkdir dir
      FileUtils.mv fname, File.join(dir, "index.#{ext}")
    end
  end
end

namespace :writeups do
  desc "Create new writeup"
  task :new do
    launch_editor new_post('Writeup', 'categories' => ['writeup'])
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
