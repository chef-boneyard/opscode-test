#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Author:: Nuo Yan <nuo@opscode.com>
# Cookbook Name:: couchdb
# Recipe:: default
#
# Copyright 2009, OpsCode, Inc
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

include_recipe "erlang_binary"
include_recipe "build-essential"

if node[:platform_version].to_f < 9.10
  couchdb_prereq = ["libicu38", "libicu-dev", "libmozjs-dev" ]
elsif node[:platform_version].to_f == 9.10
  couchdb_prereq = ["libicu40", "libicu-dev", "libmozjs-dev" ] 
else
  couchdb_prereq = ["libicu42", "libicu-dev", "xulrunner-dev" ] 
end
 
#install pre-requisites
couchdb_prereq.each do |n|
  package n 
end

cookbook_file "/etc/cron.weekly/compact_couchdb" do
  source "compact_couchdb.rb"
  mode "0755"
  backup false
end

cookbook_file "/usr/local/bin/org_cleanup" do
  source "org_cleanup"
  mode "0755"
  backup false
end

cookbook_file "/etc/cron.d/org_cleanup_cron" do
  source "org_cleanup_cron"
  mode "0755"
  backup false
end

couch_name_ver = "apache-couchdb-1.0.1"
tarball_name = "#{couch_name_ver}.tar.gz"
dest_dir = "/srv/couchdb"

unless FileTest.exists?("#{dest_dir}/bin/couchdb")

  #install couchdb (build from source)

  cookbook_file "/tmp/#{tarball_name}" do
    source tarball_name
  end
 
  script "install_#{couch_name_ver}" do
    interpreter "bash"
    user "root"
    cwd "/tmp"
    code <<-EOH
      export HOME=#{dest_dir}
      tar -zxf #{tarball_name}
      cd #{couch_name_ver}
      ./configure --prefix=#{dest_dir} --with-js-lib=/usr/lib/xulrunner-devel-1.9.2.9/lib --with-js-include=/usr/lib/xulrunner-devel-1.9.2.9/include
      make
      make install
      echo /usr/lib/xulrunner-devel-1.9.2.9/lib >> /etc/ld.so.conf.d/xul.conf
      ldconfig -v 
    EOH
  end
 
end

include_recipe "runit"

runit_service "couchdb"

template "#{node[:couchdb][:dir]}/local.ini" do
  source "local.ini.erb"
  group "root"
  owner "root"
  variables :couchdb_listen_port => node[:couchdb][:listen_port], :couchdb_listen_ip => node[:couchdb][:listen_ip]
  mode 0644
  notifies :restart, resources(:service => "couchdb")
end
