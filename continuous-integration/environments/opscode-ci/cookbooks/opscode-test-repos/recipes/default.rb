#
# Author:: Tim Hinderliter <tim@opscode.com>
# Cookbook Name:: opscode-test-repos
# Recipe:: default
#
# Copyright (c) 2010, 2011, Opscode, Inc.
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

directory "#{app['deploy_to_opscode-test']}/shared" do
  mode "0755"
  owner "opscode"
  group "opscode"
end

directory "#{app['deploy_to_opscode-test']}/shared/vendor" do
  mode "0755"
  owner "opscode"
  group "opscode"
end

deploy_revision "deploy-opscode-test" do
  revision env["opscode-test-revision"] || env['default-revision']
  repository 'git@github.com:' + (env["opscode-test-remote"] || env['default-remote']) + "/opscode-test.git"
  remote (env["opscode-test-remote"] || env['default-remote'])
  symlink_before_migrate Hash.new
  user app['owner']
  group app['group']
  deploy_to app["deploy_to_opscode-test"]
  migrate false

  # set it up so that /srv/opscode-test/1234abcd/vendor (which changes
  # with code) points to /srv/opscode-test/shared/vendor, so we don't
  # have to re-download the world every code deploy ('vendor' is
  # updated by the below bundle install step).
  symlinks("vendor" => "vendor")
  symlink_before_migrate Hash.new

  before_restart do
    execute("bundle install --deployment") do
      user "root"
      cwd "/srv/opscode-test/current"
    end
  end
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

