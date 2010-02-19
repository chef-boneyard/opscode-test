#!/usr/bin/env ruby

%w{chef couchrest mixlib-authentication mixlib-authorization mixlib-cli mixlib-config mixlib-log nginx-sysoev opscode-account opscode-audit opscode-authz opscode-authz-internal opscode-cert-erlang opscode-chef opscode-rest opscode-test opscode-usermgmt rest-client}.each do |proj|
  Dir.chdir(proj) do
    puts "-----------------------------------"
    system("echo $(pwd); git branch; git status; ruby ../opscode-test/git-wtf")
    puts "-----------------------------------"
  end
end
