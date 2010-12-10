#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: opscode-certificate
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
#

include_recipe "erlang_binary"
include_recipe "opscode-base"
include_recipe "opscode-certificate::library"

runit_service "opscode-certificate"

execute "echo cert_shut_down_service" do
  notifies :stop, resources(:service => "opscode-certificate")
  not_if do File.exist?("/srv/opscode-certificate/current/start.sh") end
end

#r = resources(:service => "opscode-certificate")
#unicorn_config "/etc/unicorn/opscode-certificate.rb" do
#  listen 5140 => { :backlog => 1024, :tcp_nodelay => true }
#  worker_timeout 3600
#  preload_app false
#  worker_processes node.cpu.total.to_i * 4
#  owner "opscode"
#  group "opscode"
#  mode "0644"
#  notifies :restart, r
#end

