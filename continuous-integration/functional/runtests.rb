class << @self
  require "#{File.dirname(__FILE__)}/cmdutil"
end

# the tests
git "git@github.com:opscode/opscode-test"

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

features = ["features:api:cookbooks:cookbook_tarballs", "features:api:cookbooks:cookbooks",
            "features:api:cookbooks:list_cookbooks", 
            "features:api:data:data", "features:api:data:delete", "features:api:data:item",
            "features:api:nodes:nodes", 
            "features:api:search:list", "features:api:search:search", "features:api:search:show"]
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
