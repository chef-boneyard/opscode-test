#!/usr/bin/env ruby

# TODO:
# how do i give ruby capability to my remote servers?

require "yaml"

class << @self
  require "#{File.dirname(__FILE__)}/cmdutil"
end

puts "** Test setup: Bootstrapping CouchDB..."
run "ruby #{File.dirname(__FILE__)}/bootstrap_couchdb.rb opscode-test/continuous-integration/functional/authorization_design_documents.couchdb-dump"


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

