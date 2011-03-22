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

app = node["apps"]["parkplace"]
env = node["environment"]

# parkplace needs this specific version of activesupport
gem_dir = Dir['/srv/localgems/gems/*']
rubyforge_gems = {
  'activesupport' => 'http://rubyforge.org/frs/download.php/47166/activesupport-2.2.2.gem',
  'activerecord' => 'http://rubyforge.org/frs/download.php/47169/activerecord-2.2.2.gem',
  'activeresource' => 'http://rubyforge.org/frs/download.php/47178/activeresource-2.2.2.gem'
}
rubyforge_gems.each do |name, url|
  unless gem_dir.find{|d|d=~/#{name}/}
    filename = "/tmp/rubyforge-gem-#{name}.gem"
    cookbook_file filename do
      source url
    end
  
    script "install activesupport gem #{name}" do
      interpreter "bash"
      user "root"
      code <<-EOH
        export GEM_HOME=/srv/localgems
        export GEM_PATH=/srv/localgems
        export PATH="/srv/localgems/bin:$PATH"
        gem install #{filename}
      EOH
    end
  end
end

directory app['deploy_to'] do
  owner app['owner']
  group app['group']
  mode '2775'
  recursive true
end

# Park place home can't be in /srv if it's an NFS mount, as Parkplace uses SQLite3 
# database, whose locking model doesn't work over NFS.
#directory "/srv/parkplace/shared/home" do
directory "/var/run/parkplace-home" do
  mode "0755"
  owner app['owner']
  group app['group']
  recursive true
end


deploy_revision app['id'] do
  #action :force_deploy
  revision env['parkplace-revision'] || env['default-revision']
  repository 'git@github.com:' + (env['parkplace-remote'] || env['default-remote']) + '/parkplace.git'
  remote (env['parkplace-remote'] || env['default-remote'])
  symlink_before_migrate Hash.new
  user app['owner']
  group app['group']
  deploy_to app['deploy_to']
  migrate false
end


include_recipe "runit"

runit_service "parkplace"

