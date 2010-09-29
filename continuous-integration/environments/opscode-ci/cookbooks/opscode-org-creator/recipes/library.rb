#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Author:: Tim Hinderliter <tim@opscode.com>
# Cookbook Name:: opscode-org-creator
# Recipe:: library
#
# Copyright 2010, Opscode, Inc.
#

include_recipe "opscode-base"
env = node['environment']
app = node['apps']['opscode-org-creator']

directory app['deploy_to'] do
  owner app['owner']
  group app['group']
  mode '0755'
  recursive true
end

directory "#{app['deploy_to']}/shared" do
  owner app['owner']
  group app['group']
  mode '0755'
  recursive true
end

directory "#{app['deploy_to']}/shared/log" do
  owner app['owner']
  group app['group']
  mode '0755'
  recursive true
end

deploy_revision app['id'] do
  revision env['opscode-org-creator-revision'] || env['default-revision']
  repository 'git@github.com:' + (env['opscode-org-creator-remote'] || env['default-remote']) + '/opscode-org-creator.git'
  remote (env['opscode-org-creator-remote'] || env['default-remote'])
  restart_command "if test -f /srv/opscode-org-creator/current/rel/org_app/etc/app.config; then /etc/init.d/opscode-org-creator restart; fi"
  symlink_before_migrate Hash.new
  user app['owner']
  group app['group']
  deploy_to app['deploy_to']
  migrate false
  before_symlink do
    bash "finalize_update" do
      user "root"
      cwd "#{release_path}"
      code <<-EOH
              export GEM_HOME=/srv/localgems
              export GEM_PATH=/srv/localgems
              export PATH=/srv/localgems/bin:$PATH
              export HOME=/tmp
              ln -s #{app['deploy_to']}/shared/log #{release_path}/rel/org_app/log
              touch #{release_path}/rel/org_app/etc/app.config
              cd #{release_path} && make rel
      EOH
    end
  end
end
