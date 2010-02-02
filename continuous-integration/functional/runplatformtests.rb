#!/usr/bin/env ruby

# TODO:
# how do i give ruby capability to my remote servers?

class << @self
  require "#{File.dirname(__FILE__)}/cmdutil"
end

features_available = []
Dir.chdir("opscode-chef") do |dir|
  File.popen("rake -T", "r") do |rake|
    rake.each_line do |line|
      #rake features:api                              # Run Features with Cucumber
      if line =~ /rake (features:[\S]+)\s+\#.*/
        features_available << $1
      end
    end
  end
end

features_pattern = ARGV[0]
if features_pattern.nil?
  $stderr.puts "runplatformtests.rb <pattern>"
  $stderr.puts "  Pattern is a regex specifying which 'features' tests to run."
  $stderr.puts "  Features available = #{features_available.join(' ')}"
  exit 1
end
  

# the tests
features = features_available.find_all { |feature| feature =~ /#{features_pattern}/ }
puts "matching features: #{features.join(' ')}"
exit 0


puts
puts
puts "********************"
puts "       TESTS        "
puts "********************"
puts "**** TEST: opscode-test ****"
Dir.chdir("opscode-test") do |dir|
  run "sudo mkdir /etc/chef", true   # it's ok if this fails, in case the directory already exists
  run "sudo cp local-test-client.rb /etc/chef/client.rb"
  run "rake setup:from_platform"
  run "rake setup:test"
end

features.each do |feature|
  Dir.chdir("opscode-chef") do |dir|
    puts "**** FEATURE TEST: opscode-chef/#{feature} ****"
    run "sudo rake #{feature}"
    puts
  end
  Dir.chdir("opscode-test") do |dir|
    run "sudo rake cleanup:replicas"
  end
end

