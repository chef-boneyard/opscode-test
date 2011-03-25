#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: opscode-webui
# Recipe:: default
#
# Copyright 2010, Opscode, Inc.
#

include_recipe "opscode-base"
include_recipe "opscode-account::library"
include_recipe "opscode-chef::library"
include_recipe "unicorn"

chargify = node["chargify"]
env = node["environment"]

link "/etc/opscode/webui_priv.pem" do
  to "/srv/opscode-chef/current/chef-server-webui/lib/webui_priv.pem"
end

template "/srv/opscode-chef/current/chef-server-webui/config/environments/cucumber.rb" do
  source "opscode-webui-config.rb.erb"
  owner "opscode"
  group "opscode"
  mode "644"
  variables(
    :int_lb_dns => env['int-lb-dns'],
    :community_servername => env['community_servername'],
    :chargify => chargify
  )
end

template "/srv/opscode-chef/current/chef-server-webui/config.ru" do
  source "opscode-webui-config.ru.erb"
  owner "opscode"
  group "opscode"
  mode "644"

  variables(:cookie_secret => "continuous-integration-1234abcd")
end

unicorn_config "/etc/unicorn/opscode-webui.rb" do
  listen 4500 => { :backlog => 1024, :tcp_nodelay => true }
  worker_timeout 3600
  preload_app false
  worker_processes node.cpu.total.to_i * 4
  owner "opscode"
  group "opscode"
  mode "0644"
end

runit_service "opscode-webui"
service = resources(:service => "opscode-webui")
service.subscribes(:restart, resources(:template => "/etc/unicorn/opscode-webui.rb"))
service.subscribes(:restart, resources(:template => "/srv/opscode-chef/current/chef-server-webui/config/environments/cucumber.rb"))
