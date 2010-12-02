#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: opscode-account
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
#

include_recipe "opscode-base"
include_recipe "unicorn"
include_recipe "chef"

include_recipe "opscode-account::library"
chargify = node["chargify"]
env = node["environment"]

couchdb_servers = [ node ]
authz_servers = [ node ]
audit_servers = [ node ]

template "/srv/opscode-account/current/config/init.rb" do
  source "init.rb.erb"
  owner "opscode"
  group "opscode"
  mode "644"
  variables(
    :couchdb_server => couchdb_servers[0],
    :authorization_server => authz_servers[0],
    :audit_server => audit_servers[0],
    :int_lb_dns => env['int-lb-dns'],
    :rabbitmq_host => audit_servers[0],
    :rabbitmq_user => "chef",
    :rabbitmq_password => node["apps"]["rabbitmq"]["users"]["chef"]
  )
end

template "/srv/opscode-account/current/config/environments/cucumber.rb" do
  source "opscode-account-config.rb.erb"
  owner "opscode"
  group "opscode"
  mode "644"
  variables(
    :chargify => chargify
  )
end

template "/srv/opscode-account/current/config.ru" do
  source "opscode-account-config.ru.erb"
  owner "opscode"
  group "opscode"
  mode "644"
end

runit_service "opscode-account" do
  only_if !File.exist?("/srv/opscode-account/current/bin/opscode-account")
end
r = resources(:service => "opscode-account")
r.subscribes(:restart, resources(:template => "/srv/opscode-account/current/config/init.rb"))
r.subscribes(:restart, resources(:deploy => "opscode-account"))

unicorn_config "/etc/unicorn/opscode-account.rb" do
  listen 4042 => { :backlog => 1024, :tcp_nodelay => true }
  worker_timeout 3600
  preload_app false
  worker_processes node.cpu.total.to_i * 4
  owner "opscode"
  group "opscode"
  mode "0644"
  notifies :restart, r
end

