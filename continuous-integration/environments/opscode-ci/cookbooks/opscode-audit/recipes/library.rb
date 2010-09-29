#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Author:: Nuo Yan <nuo@opscode.com>
# Cookbook Name:: opscode-audit
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
#

include_recipe "opscode-base"

env = node["environment"]
app = node["apps"]["opscode-audit"]

directory app['deploy_to'] do
  owner app['owner']
  group app['group']
  mode '0755'
  recursive true
end

deploy_revision app['id'] do
  #action :force_deploy
  revision env['opscode-audit-revision'] || env['default-revision']
  repository 'git@github.com:' + (env['opscode-audit-remote'] || env['default-remote']) + '/opscode-audit.git'
  remote (env['opscode-audit-remote'] || env['default-remote'])
  restart_command "if test -L /etc/init.d/opscode-account; then sudo /etc/init.d/opscode-audit restart; fi"
  symlink_before_migrate Hash.new
  user app['owner']
  group app['group']
  deploy_to app['deploy_to']
  migrate false
end

