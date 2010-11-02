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

directory "/srv/opscode-account/shared/vendor" do
  mode "0755"
  owner "opscode"
  group "opscode"
end

deploy_revision app['id'] do
  #action :force_deploy
  revision env['opscode-account-revision'] || env['default-revision']
  repository 'git@github.com:' + (env['opscode-account-remote'] || env['default-remote']) + '/opscode-account.git'
  remote (env['opscode-account-remote'] || env['default-remote'])
  # Add 'vendor' => 'vendor' to the default symlinks so we won't have to rebuild
  # the bundle for each deploy.
  symlinks("system" => "public/system", "pids" => "tmp/pids", "log" => "log", "vendor" => "vendor")

  symlink_before_migrate Hash.new
  user app['owner']
  group app['group']
  deploy_to app['deploy_to']
  migrate false

  before_restart do
    execute("bundle install --deployment") do
      cwd("/srv/opscode-account/current")
      user(app['owner'])
      group(app['group'])
    end
  end

  ##restart_command "if test -f /etc/unicorn/opscode-account.rb; then /etc/init.d/opscode-account restart; fi"
end

#directory "/srv/opscode-chef/shared/cookbooks_cache" do
 # mode "0755"
 # owner "opscode"
 # group "opscode"
#end
