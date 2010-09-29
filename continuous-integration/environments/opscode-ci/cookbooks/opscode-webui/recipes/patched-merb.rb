#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: opscode-webui
# Recipe:: patched-merb
#
# Copyright 2010, Opscode, Inc.
#

env = data_bag_item(:environments, node.app_environment)
app = {
  'id' => "merb",
  'deploy_to' => "/srv/merb",
  'owner' => 'root',
  'group' => 'root'
}

directory "/srv/merb" do
  owner "root"
  group "root"
  mode '0755'
  recursive true
end

deploy_revision app['id'] do
  revision env['merb-revision'] || env['default-revision']
  repository 'git@github.com:' + (env['merb-remote'] || env['default-remote']) + '/merb.git'
  remote (env['merb-remote'] || env['default-remote'])
  symlink_before_migrate Hash.new
  user app['owner']
  group app['group']
  deploy_to app['deploy_to']
  migrate false
  before_symlink do
    bash "install_gem_local" do
      user "root"
      cwd "#{release_path}"
      code <<-EOH
        export "GEM_HOME=/srv/localgems"
        export "GEM_PATH=/srv/localgems"
        export "PATH=/srv/localgems/bin:$PATH"
        rake build
        gem install merb-core/pkg/*.gem
      EOH
    end
  end
end

