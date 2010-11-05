#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: chef
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
#

include_recipe "opscode-base"

env = node["environment"]

directory "/srv/chef" do
  owner "root"
  group "root"
  mode '0755'
  recursive true
end

deploy_revision 'chef' do
  #action :force_deploy
  revision env['chef-revision'] || env['default-revision']
  repository 'git://github.com/' + (env['chef-remote'] || env['default-remote']) + '/chef.git'
  remote (env['chef-remote'] || env['default-remote'])
  symlink_before_migrate Hash.new
  user "root"
  group "root"
  deploy_to "/srv/chef"
  migrate false
  before_symlink do
    bash "install_gem_local" do
      user "root"
      cwd "#{release_path}"
      code <<-EOH
          export "GEM_HOME=/srv/localgems"
          export "GEM_PATH=/srv/localgems"
          export "PATH=/srv/localgems/bin:$PATH"
          cd chef
          rake gem
          gem install pkg/*.gem
          cd ../chef-solr
          rake gem
          gem install pkg/*.gem
      EOH
    end
  end
end
