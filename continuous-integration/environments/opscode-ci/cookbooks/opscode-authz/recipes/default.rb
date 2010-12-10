#
# Author:: Adam Jacob <adam@opscode.com>
# Cookbook Name:: opscode-authz
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.

include_recipe "erlang_binary"
include_recipe "opscode-base"
include_recipe "opscode-authz::piab-dbs-setup-test"

env = node["environment"]
app = {
  'id' => "opscode-authz",
  'deploy_to' => "/srv/opscode-authz",
  'owner' => 'opscode',
  'group' => 'opscode'
}

# BUG in the git provider prevents us from cloning the repo into an
# existing directory :(
# directory app['deploy_to'] do
#   owner app['owner']
#   group app['group']
#   mode '0755'
#   recursive true
# end

authz_rev = env['opscode-authz-revision'] || env['default-revision']

## Then, deploy
myrevision = env['opscode-authz-revision'] || env['default-revision']

git "opscode-authz" do

  action(:sync)

  destination "/srv/opscode-authz"
  revision env['opscode-authz-revision'] || env['default-revision']
  repository 'git@github.com:' + (env['opscode-authz-remote'] || env['default-remote']) + '/opscode-authz.git'
  remote (env['opscode-authz-remote'] || env['default-remote'])
  #user app['owner']
  #group app['group']
  notifies :run, "execute[git-reset-hard-authz-code]", :immediately
  notifies(:run, "bash[recompile_authz]", :immediately)
end

execute "git-reset-hard-authz-code" do
  command "git reset --hard"
  cwd "/srv/opscode-authz"
end

couchdb_authz_server = 'localhost'

template "/srv/opscode-authz/authz.config" do
  source "authz.config.erb"
  owner "opscode"
  group "opscode"
  mode "644"
  variables(:couchdb_authz_server => couchdb_authz_server)
  notifies(:restart, "service[opscode-authz]")
end

bash "recompile_authz" do
  #run "no"
  action :nothing
  user "root"
  cwd "/srv/opscode-authz"
  code <<-EOH
    export HOME=/tmp
    cd /srv/opscode-authz/
    make clean
    make
  EOH
  notifies(:restart, "service[opscode-authz]")
end

runit_service "opscode-authz"
