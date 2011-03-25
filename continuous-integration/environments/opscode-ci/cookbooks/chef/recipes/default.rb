#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Author:: Tim Hinderliter <tim@opscode.com>
# Cookbook Name:: chef
# Recipe:: default
#
# Copyright 2009, 2011, Opscode, Inc.
#

include_recipe "opscode-base"

env = node["environment"]

["/srv/chef", "/srv/chef/shared", "/srv/chef/shared/vendor_chef_expander"].each do |dirname|
  directory dirname do
    owner "opscode"
    group "opscode"
    mode '0755'
  end
end

deploy_revision 'chef' do
  revision env['chef-revision'] || env['default-revision']
  repository 'git://github.com/' + (env['chef-remote'] || env['default-remote']) + '/chef.git'
  remote (env['chef-remote'] || env['default-remote'])

  user "opscode"
  group "opscode"
  deploy_to "/srv/chef"

  symlink_before_migrate Hash.new
  symlinks("vendor_chef_expander" => "chef-expander/vendor")

  migrate false
  before_symlink do
    bash "install_localgems_chef" do
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
