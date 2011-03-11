#
# Author:: Tim Hinderliter <tim@opscode.com>
# Cookbook Name:: chef-solr
# Recipe:: default
#
# Copyright 2011, Opscode, Inc.
#

include_recipe "opscode-base"
include_recipe "java"

app = node["apps"]["chef-solr"]
env = node["environment"]

couchdb_servers = [ node ] 
audit_servers = [ node ] 

directory "/srv/chef-solr" do
  owner "opscode"
  group "opscode"
  mode "0755"
end

directory "/srv/chef-solr/shared" do
  owner "opscode"
  group "opscode"
  mode "0755"
end

directory "/srv/chef-solr/shared/system" do
  owner "opscode"
  group "opscode"
  mode "0755"
end

solr_conf = "/srv/chef-solr/shared/chef-solr.conf"
template solr_conf do
  source "chef-solr.conf.erb"
  owner "opscode"
  group "opscode"
  mode "644"
  variables(
    :int_lb_dns => env['int-lb-dns'],
    :rabbitmq_host => audit_servers[0],
    :rabbitmq_user => "chef",
    :rabbitmq_password => node["apps"]["rabbitmq"]["users"]["chef"],
    :couchdb_server => couchdb_servers[0]
  )
end

script "install_solr_config" do
  interpreter "bash"
  user "opscode"
  group "opscode"
  #action :nothing
  code <<-EOH
    cd /srv/chef/current/chef-solr
    bin/chef-solr-installer -c #{solr_conf} -p /srv/chef-solr/shared/system/ --force
  EOH

  #subscribes :run, resources(:deploy => 'chef'), :immediately
end

runit_service "chef-solr"

solr_conf_res = resources(:template => solr_conf)
chef_deploy_res = resources(:deploy => 'chef')

chef_solr_service = resources(:service => 'chef-solr')
chef_solr_service.subscribes(:restart, solr_conf_res)
chef_solr_service.subscribes(:restart, chef_deploy_res)

execute "echo shut_down #{daemon}" do
  notifies :stop, chef_solr_service
  not_if do File.exist?("/srv/chef/current/chef-solr/bin/chef-solr") end
end

