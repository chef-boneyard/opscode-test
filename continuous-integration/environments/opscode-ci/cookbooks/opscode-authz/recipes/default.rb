#
# Author:: Adam Jacob <adam@opscode.com>
# Cookbook Name:: opscode-authz
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.

include_recipe "erlang"
include_recipe "opscode-base"

env = node["environment"]
app = node["apps"]["opscode-authz"]

runit_service "opscode-authz"

execute "echo authz_shut_down_service" do
  notifies :stop, resources(:service => "opscode-authz")
  not_if do File.exist?("/srv/opscode-authz/current/start.sh") end
end

directory app['deploy_to'] do
  owner app['owner']
  group app['group']
  mode '0755'
  recursive true
end

authz_rev = env['opscode-authz-revision'] || env['default-revision']

## Then, deploy
deploy_revision app['id'] do
  #action :force_deploy
  revision env['opscode-authz-revision'] || env['default-revision']
  repository 'git@github.com:' + (env['opscode-authz-remote'] || env['default-remote']) + '/opscode-authz.git'
  remote (env['opscode-authz-remote'] || env['default-remote'])
  restart_command "if test -L /etc/init.d/opscode-authz; then /etc/init.d/opscode-authz restart; fi"
  symlink_before_migrate Hash.new
  user app['owner']
  group app['group']
  deploy_to app['deploy_to']
  migrate false
  before_symlink do
    bash "finalize_update" do
      user "root"
      #user "opscode"
      cwd "#{release_path}"
      code <<-EOH
            export GEM_HOME=/srv/localgems
            export GEM_PATH=/srv/localgems
            export PATH=/srv/localgems/bin:$PATH
            export HOME=/tmp
            cd #{release_path} && make clean  && touch made-clean
            cd #{release_path} && make && touch made-it
      EOH

    end

  end
end

couchdb_servers = [ node ]

bash "recompile_authz" do
  #run "no"
  action :nothing
  user "root"
  cwd "/srv/opscode-authz/current"
  code <<-EOH
    export GEM_HOME=/srv/localgems
    export GEM_PATH=/srv/localgems
    export PATH=/srv/localgems/bin:$PATH
    export HOME=/tmp
    cd /srv/opscode-authz/current/ && make
    /etc/init.d/opscode-authz restart
  EOH
end

template "/srv/opscode-authz/current/deps/opscode-authz-internal/lib/opscode_authz/include/auth.hrl" do
  source "auth.hrl.erb"
  owner "opscode"
  group "opscode"
  mode "644"
  variables(
    :couchdb_server => couchdb_servers[0],
    :int_lb_dns => env['int-lb-dns']
  )
  notifies :run, resources(:bash => "recompile_authz"), :immediately
end

