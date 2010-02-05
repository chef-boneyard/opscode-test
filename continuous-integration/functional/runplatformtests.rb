#!/usr/bin/env ruby

# TODO:
# how do i give ruby capability to my remote servers?

require "yaml"

class << @self
  require "#{File.dirname(__FILE__)}/cmdutil"
end

# cucumber.yml holds the mapping of cucumber aliases to cucumber 
# invocation arguments. "rake features:api:search:list", e.g., refers 
# to alias "api_search_list". This script invokes "cucumber" directly
# instead of using the "rake features:api..." wrappers as we need
# to explicitly change the cucumber formatter for JUNIT output.
features_available = YAML::load(File::read('opscode-chef/cucumber.yml'))

puts "ALL FEATURES:"
puts "    #{features_available.keys.join(' ')}"
puts
features_pattern = ARGV[0]
if features_pattern.nil?
  $stderr.puts "runplatformtests.rb <pattern>"
  $stderr.puts "  Pattern is a regex specifying which 'features' tests to run. These"
  $stderr.puts "  are pulled from cucumber.yml."
  exit 1
end
  

# the tests that will be run.
feature_names_to_run = features_available.keys.find_all { |feature_name| feature_name =~ /#{features_pattern}/ }
puts "MATCHING FEATURES (going to run):"
puts "    #{feature_names_to_run.join(' ')}"
puts
if feature_names_to_run.length == 0
  raise ArgumentError, "No features match your pattern, exiting."
end

# If JUNIT XML output was specified, build a command line.
cucumber_options = "--format pretty"
if ARGV.length == 3 && ARGV[1] == "--junit-out"
  cucumber_options = "--format junit --out '#{ARGV[2]}'"
end

# Determine the path for cucumber binary
gem_path = `gem env gemdir`.chomp
cucumber_path = "#{gem_path}/bin/cucumber"
if !File.exists?(cucumber_path)
  cucumber_path = "cucumber"
end

puts "**** TEST SETUP: opscode-test: setup:from_platform; setup:test ****"
Dir.chdir("opscode-test") do |dir|
  run "sudo mkdir /etc/chef", true   # it's ok if this fails, in case the directory already exists
  run "sudo cp local-test-client.rb /etc/chef/client.rb"
  run "rake setup:from_platform"
  run "rake setup:test"
end

puts
puts
puts "********************"
puts "*      TESTS       *"
puts "********************"

# Run each feature test, 
feature_names_to_run.each do |feature_name|
  feature_arg = features_available[feature_name]

  # strip any pretty formatting that was specified in the config.
  feature_arg = feature_arg.gsub /--format pretty/, ""
  feature_arg = feature_arg.gsub /-f pretty/, ""

  Dir.chdir("opscode-chef") do |dir|
    puts "****"
    puts "**** FEATURE TEST: opscode-chef:#{feature_name} ****"
    puts "****"
    run "sudo #{cucumber_path} #{feature_arg} #{cucumber_options}", true  # ignore errors and keep going
    puts
  end

  puts "** Restarting CouchDB"
  run "ruby opscode-test/continuous-integration/functional/restart_couchdb.rb"

  puts "** Cleanup Replicas"
  Dir.chdir("opscode-test") do |dir|
    run "sudo rake cleanup:replicas"
  end
end

