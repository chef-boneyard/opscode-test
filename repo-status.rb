#!/usr/bin/env ruby

%w{opscode-chef mixlib-authorization mixlib-authentication opscode-account mixlib-cli mixlib-log chef}.each do |proj|
  Dir.chdir(proj) do
    system("echo $(pwd) && git branch && git status")
  end
end
