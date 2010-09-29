#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: opscode-account
# Recipe:: library
#
# Copyright 2009, Opscode, Inc.
#

env = node["environment"]
app = node["apps"]["opscode-account"]

directory app['deploy_to'] do
  owner app['owner']
  group app['group']
  mode '2775'
  recursive true
end

deploy_revision app['id'] do
  #action :force_deploy
  revision env['opscode-account-revision'] || env['default-revision']
  repository 'git@github.com:' + (env['opscode-account-remote'] || env['default-remote']) + '/opscode-account.git'
  remote (env['opscode-account-remote'] || env['default-remote'])
  symlink_before_migrate Hash.new
  user app['owner']
  group app['group']
  deploy_to app['deploy_to']
  migrate false
  ##restart_command "if test -f /etc/unicorn/opscode-account.rb; then /etc/init.d/opscode-account restart; fi"
end

#directory "/srv/opscode-chef/shared/cookbooks_cache" do
 # mode "0755"
 # owner "opscode"
 # group "opscode"
#end
