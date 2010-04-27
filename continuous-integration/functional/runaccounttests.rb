#!/usr/bin/env ruby

require "yaml"

class << @self
  require "#{File.dirname(__FILE__)}/cmdutil"
end

puts "** Test setup: Bootstrapping CouchDB..."
run "ruby #{File.dirname(__FILE__)}/bootstrap_couchdb.rb opscode-test/continuous-integration/functional/authorization_design_documents.couchdb-dump"

puts "**** TEST SETUP: opscode-test: setup:from_platform; setup:test ****"
Dir.chdir("opscode-test") do |dir|
  run "sudo mkdir /etc/chef", true   # it's ok if this fails, in case the directory already exists
  run "sudo cp local-test-client.rb /etc/chef/client.rb"
  run "rake setup:from_platform"
  run "rake setup:test"
end


# Determine the path for cucumber binary
gem_path = `gem env gemdir`.chomp
cucumber_path = "#{gem_path}/bin/cucumber"
if !File.exists?(cucumber_path)
  cucumber_path = "cucumber"
end

# If JUNIT XML output was specified, build a command line.
cucumber_options = "--format pretty"
if ARGV.length == 2 && ARGV[0] == "--junit-out"
  cucumber_options = "--format junit --out '#{ARGV[1]}'"
end

puts
puts
puts "********************"
puts "*      TESTS       *"
puts "********************"
Dir.chdir("opscode-account") do |dir|
  run "#{cucumber_path} #{cucumber_options}"
end

