#
# Author:: Tim Hinderliter <tim@opscode.com>
# Cookbook Name:: parkplace
# Recipe:: default
#
# Copyright 2010, 2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "runit"

env = node["environment"]

# Park place home can't be in /srv if it's an NFS mount, as Parkplace
# uses SQLite3 database, whose locking model doesn't work over NFS.
directory "/var/run/parkplace-home" do
  mode "0755"
  owner "root"
  group "root"
  recursive true
end

["/srv/parkplace", "/srv/parkplace/shared", "/srv/parkplace/shared/vendor"].each do |dirname|
  directory dirname do
    mode "0755"
    owner "root"
    group "root"
  end
end

deploy_revision "parkplace" do
  #action :force_deploy
  revision env['parkplace-revision'] || env['default-revision']
  repository 'git@github.com:' + (env['parkplace-remote'] || env['default-remote']) + '/parkplace.git'
  remote (env['parkplace-remote'] || env['default-remote'])

  user "root"
  group "root"
  deploy_to "/srv/parkplace"
  migrate false

  # set it up so that /srv/parkplace/1234abcd/vendor (which changes
  # with code) points to /srv/parkplace/shared/vendor, so we don't
  # have to re-download the world every code deploy ('vendor' is
  # updated by the below bundle install step).
  symlinks("vendor" => "vendor")
  symlink_before_migrate Hash.new

  before_restart do
    execute("bundle install --deployment") do
      user "root"
      cwd "/srv/parkplace/current"
    end
  end
end


runit_service "parkplace"

