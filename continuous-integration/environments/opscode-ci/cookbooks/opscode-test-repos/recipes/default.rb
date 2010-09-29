#
# Author:: Tim Hinderliter <tim@opscode.com>
# Cookbook Name:: opscode-test
# Recipe:: client
#
# Copyright 2010, Opscode, Inc.
#

include_recipe "opscode-base"

env = node["environment"]
app = node["apps"]["opscode-test-repos"]

#-------------
# opscode-test
#-------------
directory app["deploy_to_opscode-test"] do
  owner app['owner']
  group app['group']
  mode '0755'
  recursive true
end

deploy_revision "deploy-opscode-test" do
  #action :force_deploy
  revision env["opscode-test-revision"] || env['default-revision']
  repository 'git@github.com:' + (env["opscode-test-remote"] || env['default-remote']) + "/opscode-test.git"
  remote (env["opscode-test-remote"] || env['default-remote'])
  symlink_before_migrate Hash.new
  user app['owner']
  group app['group']
  deploy_to app["deploy_to_opscode-test"]
  migrate false
end

# ----------------
# opscode-cucumber
# ----------------
directory app["deploy_to_opscode-cucumber"] do
  owner app['owner']
  group app['group']
  mode '0755'
  recursive true
end

deploy_revision "deploy-opscode-cucumber" do
  #action :force_deploy
  revision env["opscode-cucumber-revision"] || env['default-revision']
  repository 'git@github.com:' + (env["opscode-cucumber-remote"] || env['default-remote']) + "/opscode-cucumber.git"
  remote (env["opscode-cucumber-remote"] || env['default-remote'])
  symlink_before_migrate Hash.new
  user app['owner']
  group app['group']
  deploy_to app["deploy_to_opscode-cucumber"]
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
          rake repackage || rake build
          gem install pkg/*.gem 
      EOH
    end
  end
end

