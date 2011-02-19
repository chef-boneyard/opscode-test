#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: opscode-chef
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
#

gem_package "bundler"

include_recipe "opscode-base"

env = node["environment"]
app = node["apps"]["opscode-chef"]

directory app['deploy_to'] do
  owner app['owner']
  group app['group']
  mode '0755'
  recursive true
end

directory "#{app['deploy_to']}/shared" do
  mode "0755"
  owner "opscode"
  group "opscode"
end

directory "#{app['deploy_to']}/shared/vendor" do
  mode "0755"
  owner "opscode"
  group "opscode"
end

deploy_revision app['id'] do
  #action :force_deploy
  revision env['opscode-chef-revision'] || env['default-revision']
  repository 'git@github.com:' + (env['opscode-chef-remote'] || env['default-remote']) + '/opscode-chef.git'
  remote (env['opscode-chef-remote'] || env['default-remote'])
  ##restart_command "if test -L /etc/init.d/opscode-chef; then sudo /etc/init.d/opscode-chef restart; fi"
  symlinks("system" => "public/system", "pids" => "tmp/pids", "log" => "log", "vendor" => "vendor")
  symlink_before_migrate Hash.new
  user app['owner']
  group app['group']
  deploy_to app['deploy_to']
  migrate false

  before_restart do
    execute("bundle install --deployment") do
      cwd("/srv/opscode-chef/current")
      user(app['owner'])
      group(app['group'])
    end
  end

end

directory "/srv/opscode-chef/shared/cookbooks_cache" do
  mode "0755"
  owner "opscode"
  group "opscode"
end

