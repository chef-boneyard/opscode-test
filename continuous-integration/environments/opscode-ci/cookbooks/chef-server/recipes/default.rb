#
# Author:: Tim Hinderliter <tim@opscode.com>
# Cookbook Name:: chef-server
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
#

include_recipe "unicorn"
include_recipe "chef"

env = node["environment"]

# exec("./chef-server-api/bin/chef-server -a thin -C #{File.join(File.dirname(__FILE__), "features", "data", "config", "server.rb")} -l debug -N")

runit_service "chef-server"
resources(:service => "chef-server").subscribes(:restart, resources(:deploy => "chef-server"))

directory "/srv/chef/shared" do
  owner 'opscode'
  group 'opscode'
  mode '0755'
  recursive true
end

# Server configuration.
cookbook_file "/etc/chef/server.rb" do
  source "server.rb"
end

r = resources(:service => "chef-server")
unicorn_config "/etc/unicorn/chef.rb" do
  listen 4000 => { :backlog => 1024, :tcp_nodelay => true }
  worker_timeout 3600
  preload_app false
  worker_processes node.cpu.total.to_i * 4
  owner "opscode"
  group "opscode"
  mode "0644"
  notifies :restart, r
end
