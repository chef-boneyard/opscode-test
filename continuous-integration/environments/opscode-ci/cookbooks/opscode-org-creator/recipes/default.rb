#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: opscode-org-creator
# Recipe:: default
#
# Copyright 2010, Opscode, Inc.
#

include_recipe "erlang_binary" 
include_recipe "opscode-base"
include_recipe "opscode-org-creator::library"

env = node["environment"]
couchdb_server = env["couchdb_fqdn"]

cookbook_file "/etc/init.d/opscode-org-creator" do
  source "opscode-org-creator-init"
  mode "0755"
  owner "root"
  group "root"
  backup 0
end

template "/srv/opscode-org-creator/current/rel/org_app/etc/app.config" do
  source "app.config.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    :couchdb_server => couchdb_server,
    :int_lb_dns => env['int-lb-dns'],
    :max_workers => env['org_creator_max_workers'],
    :ready_org_depth => env['org_creator_ready_org_depth'],
    :org_create_wait_ms => env['org_creator_create_wait_ms'],
    :org_create_splay_ms => env['org_creator_create_splay_ms']
  )
end

service "opscode-org-creator" do
  supports :restart => true
  action [:enable, :start]
  subscribes :restart, resources(:template => "/srv/opscode-org-creator/current/rel/org_app/etc/app.config")
end

