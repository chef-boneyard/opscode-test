#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: opscode-github
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
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

directory "/root/.ssh" 

cookbook_file "/root/.ssh/github" do
  source "opscode-github-sshkey"
  mode '0600'
  owner 'root'
end

remote_file "/root/.ssh/config" do
  source "ssh_config"
end

group "opscode" do
  gid 5049
end

user "opscode" do
  comment "Opscode User"
  shell "/bin/sh"
  uid 5049
  gid 5049
end

directory "/home/opscode" do
  owner "opscode"
  group "opscode"
end

directory "/home/opscode/.ssh" do
  owner "opscode"
  group "opscode"
end

remote_file "/home/opscode/.ssh/github" do
  source "opscode-github-sshkey"
  owner "opscode"
  group "opscode"
  mode 0600
end

remote_file "/home/opscode/.ssh/config" do
  source "ssh_config"
  owner "opscode"
  group "opscode"
  mode 0600
end
