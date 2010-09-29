#
# Author:: Adam Jacob <adam@opscode.com>
# Cookbook Name:: opscode-solr
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
#

include_recipe "opscode-base"
include_recipe "java"

app = node["apps"]["opscode-solr"]
env = node["environment"]

directory app['deploy_to'] do
  owner app['owner']
  group app['group']
  mode '0755'
  recursive true
end

deploy_revision app['id'] do
  #action :force_deploy
  revision env['opscode-solr-revision'] || env['default-revision']
  repository 'git://github.com/' + (env['opscode-solr-remote'] || env['default-remote']) + '/chef.git'
  remote (env['opscode-solr-remote'] || env['default-remote'])
  ##restart_command "if test -L /etc/init.d/opscode-solr; then (/etc/init.d/opscode-solr restart && /etc/init.d/opscode-solr-indexer restart) ; fi"
  symlink_before_migrate Hash.new
  user app['owner']
  group app['group']
  deploy_to app['deploy_to']
  migrate false
end

couchdb_servers = [ node ] 
audit_servers = [ node ] 
solr_conf = "/srv/opscode-solr/current/chef-solr/opscode-solr.conf"

template solr_conf do
  source "opscode-solr.conf.erb"
  owner "opscode"
  group "opscode"
  mode "644"
  variables(
    :int_lb_dns => env['int-lb-dns'],
    :rabbitmq_host => audit_servers[0],
    :rabbitmq_user => "chef",
    :rabbitmq_password => node["apps"]["rabbitmq"]["users"]["chef"],
    :couchdb_server => couchdb_servers[0]
    #:account_server => "localhost",
    #:solr_server => "localhost",
    #:audit_server => "localhost"
  )
  #notifies :restart, resources(:service => "opscode-solr", :service => "opscode-solr-indexer")
  ##notifies :restart, resources(:service => "opscode-solr")
  ##notifies :restart, resources(:service => "opscode-solr-indexer")
end

runit_service "opscode-solr"
runit_service "opscode-solr-indexer"

solr_conf_res = resources(:template => solr_conf)
solr_deploy_res = resources(:deploy => app['id'])

%w{opscode-solr opscode-solr-indexer}.each do |s|
  r = resources(:service => s)
  r.subscribes(:restart, solr_conf_res)
  r.subscribes(:restart, solr_deploy_res)
end

%w{opscode-solr opscode-solr-indexer}.each do |daemon|
  execute "echo shut_down #{daemon}" do
    notifies :stop, resources(:service => daemon)
    not_if do File.exist?("/srv/opscode-solr/current/chef-solr/bin/chef-solr") end
  end
end


