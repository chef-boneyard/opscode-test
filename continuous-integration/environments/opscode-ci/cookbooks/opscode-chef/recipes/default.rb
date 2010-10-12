#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: opscode-chef
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
#

include_recipe "unicorn"
include_recipe "chef"
include_recipe "opscode-chef::library"
include_recipe "opscode-certificate"

aws = node["aws"]
env = node["environment"]

couchdb_servers = [ node ] 
account_servers = [ node ]
solr_servers = [ node ]
authz_servers = [ node ]
audit_servers = [ node ]

opscode_chef_conf = template "/srv/opscode-chef/current/chef-server/config/opscode-chef.conf" do
  source "opscode-chef.conf.erb"
  owner "opscode"
  group "opscode"
  mode "644"
  variables(
    :int_lb_dns => env['int-lb-dns'],
    :couchdb_server => couchdb_servers[0],
    :account_server => account_servers[0],
    :solr_server => solr_servers[0],
    :audit_server => audit_servers[0],
    :rabbitmq_user => "chef",
    :rabbitmq_password => node["apps"]["rabbitmq"]["users"]["chef"]
  )
end

opscode_chef_init = template "/srv/opscode-chef/current/chef-server-api/config/init.rb" do
  source "opscode-init.rb.erb"
  owner "opscode"
  group "opscode"
  mode "644"
  variables(
    :int_lb_dns => env['int-lb-dns'],
    :couchdb_server => couchdb_servers[0],
    :authz_server => authz_servers[0],
    :chef_env => node["app_environment"],
    :rabbitmq_host => audit_servers[0],
    :rabbitmq_user => "chef",
    :rabbitmq_password => node["apps"]["rabbitmq"]["users"]["chef"]
  )
end

runit_service "opscode-chef"
resources(:service => "opscode-chef").subscribes(:restart, opscode_chef_conf)
resources(:service => "opscode-chef").subscribes(:restart, opscode_chef_init)
resources(:service => "opscode-chef").subscribes(:restart, resources(:deploy => "opscode-chef"))

r = resources(:service => "opscode-chef")
unicorn_config "/etc/unicorn/opscode-chef.rb" do
  listen 4001 => { :backlog => 1024, :tcp_nodelay => true }
  worker_timeout 3600
  preload_app false
  worker_processes node.cpu.total.to_i * 4
  owner "opscode"
  group "opscode"
  mode "0644"
  notifies :restart, r
end

