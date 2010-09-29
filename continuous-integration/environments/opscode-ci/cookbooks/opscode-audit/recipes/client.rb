#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Author:: Nuo Yan <nuo@opscode.com>
# Cookbook Name:: opscode-audit
# Recipe:: client
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
  symlink_before_migrate Hash.new
  user app['owner']
  group app['group']
  deploy_to app['deploy_to']
  migrate false
  before_symlink do
    bash "install_audit_gem" do
      user "root"
      cwd "#{release_path}"
      code <<-EOH
            export "GEM_HOME=/srv/localgems"
            export "GEM_PATH=/srv/localgems"
            export PATH="/srv/localgems/bin:$PATH"
            rake repackage || rake build
            gem install pkg/*.gem 
      EOH
    end
  end
end

