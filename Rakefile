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
    system "gem install nanoc3 RedCloth coderay"
  end
end

desc "run a local server"
task :server do
  require 'nanoc3/cli'
  Nanoc3::CLI.run ["view"]
end
