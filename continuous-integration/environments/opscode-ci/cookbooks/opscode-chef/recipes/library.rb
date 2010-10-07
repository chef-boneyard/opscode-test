#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: opscode-chef
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
#

include_recipe "opscode-base"

env = node["environment"]
app = node["apps"]["opscode-chef"]

directory app['deploy_to'] do
  owner app['owner']
  group app['group']
  mode '0755'
  recursive true
end

deploy_revision app['id'] do
  #action :force_deploy
  revision env['opscode-chef-revision'] || env['default-revision']
  repository 'git@github.com:' + (env['opscode-chef-remote'] || env['default-remote']) + '/opscode-chef.git'
  remote (env['opscode-chef-remote'] || env['default-remote'])
  ##restart_command "if test -L /etc/init.d/opscode-chef; then sudo /etc/init.d/opscode-chef restart; fi"
  symlink_before_migrate Hash.new
  user app['owner']
  group app['group']
  deploy_to app['deploy_to']
  migrate false
end

directory "/srv/opscode-chef/shared/cookbooks_cache" do
  mode "0755"
  owner "opscode"
  group "opscode"
end

