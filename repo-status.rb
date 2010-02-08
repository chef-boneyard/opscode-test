#!/usr/bin/env ruby

%w{opscode-chef opscode-authz mixlib-authorization mixlib-authentication opscode-account mixlib-cli mixlib-log mixlib-config chef opscode-rest couchrest rest-client}.each do |proj|
  Dir.chdir(proj) do
    system("echo $(pwd) && git branch && git status")
  end
end
