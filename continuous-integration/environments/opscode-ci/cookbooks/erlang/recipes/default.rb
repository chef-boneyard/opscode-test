#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: erlang
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

include_recipe "build-essential"
include_recipe "curl"
include_recipe "ncurses"

script "install_erlang_timh_otp" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
      export HOME=/tmp
      git clone git://github.com/timh/otp
      cd otp
      ./otp_build setup
      make
      make install
  EOH
  not_if do FileTest.exists?("/usr/local/bin/erlc"); end
end


