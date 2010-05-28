#!/usr/bin/env ruby

%w{chef couchrest mixlib-authentication mixlib-authorization mixlib-localization mixlib-cli mixlib-config mixlib-log nginx-sysoev opscode-account opscode-audit opscode-authz opscode-authz-internal opscode-cert-erlang opscode-chef opscode-rest opscode-test rest-client}.each do |proj|
  Dir.chdir(proj) do
    puts "-----------------------------------"
    system("echo $(pwd); git branch; git pull; git status; ruby ../opscode-test/git-wtf")
    puts "-----------------------------------"
  end
end
