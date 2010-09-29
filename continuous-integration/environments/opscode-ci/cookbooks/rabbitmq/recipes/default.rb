#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: rabbitmq
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

include_recipe "erlang"

group "rabbitmq" do
  gid 5050
end

user "rabbitmq" do
  comment "RabbitMQ"
  uid 5050
  gid 5050
  home "/srv/rabbitmq"
  shell "/bin/sh"
end

#unless FileTest.exists?("/usr/local/lib/erlang/lib/rabbitmq_server-1.6.0/sbin/rabbitmq-server")
unless FileTest.exists?("/usr/local/lib/erlang/lib/rabbitmq_server-1.7.0/sbin/rabbitmq-server")

  #install rabbitmq-server (build from source)

  #remote_file "/usr/local/lib/erlang/lib/rabbitmq-server-generic-unix-1.6.0.tar.gz" do
  #  source "rabbitmq-server-generic-unix-1.6.0.tar.gz"
  #end

  remote_file "/usr/local/lib/erlang/lib/rabbitmq-server-generic-unix-1.7.0.tar.gz" do
    source "http://www.rabbitmq.com/releases/rabbitmq-server/v1.7.0/rabbitmq-server-generic-unix-1.7.0.tar.gz"
  end

  script "install_rabbitmq" do
    interpreter "bash"
    user "root"
    cwd "/usr/local/lib/erlang/lib/"
    code <<-EOH
      export HOME=/tmp
      tar -zxf rabbitmq-server-generic-unix-1.7.0.tar.gz
    EOH
  end

end

%w{/srv/rabbitmq /srv/rabbitmq/db /srv/rabbitmq/log}.each do |d|
  directory d do
    owner "rabbitmq"
    group "rabbitmq"
  end
end

%w{rabbitmqctl rabbitmq-server rabbitmq-multi rabbitmq-env}.each do |script|
  link "/usr/local/sbin/#{script}" do
   #to "/usr/local/lib/erlang/lib/rabbitmq_server-1.6.0/sbin/#{script}" 
   to "/usr/local/lib/erlang/lib/rabbitmq_server-1.7.0/sbin/#{script}" 
   action :create
  end
end

include_recipe "runit"

runit_service "rabbitmq"

##
# Initialize the rabbit vhosts
##

unless File.exists?("/srv/rabbitmq/delete_me_to_update_perms")

  ruby_block "sleepy" do
    block do
      sleep 10
    end
  end

  node[:apps][:rabbitmq][:vhosts].each do |vhost, perms|
    execute "add_vhost" do
      environment "HOME" => "/srv/rabbitmq"
      cwd "/srv/rabbitmq"
      user "rabbitmq"
      command "/usr/local/sbin/rabbitmqctl add_vhost #{vhost}"
    end
  end

  node[:apps][:rabbitmq][:users].each do |user, pw|
    execute "add_user" do
      environment "HOME" => "/srv/rabbitmq"
      cwd "/srv/rabbitmq"
      user "rabbitmq"
      command "/usr/local/sbin/rabbitmqctl add_user #{user} #{pw}" 
    end
  end

  node[:apps][:rabbitmq][:vhosts].each do |vhost, perms|
    perms.each do |user, priv|
      execute "set_permissions" do
        environment "HOME" => "/srv/rabbitmq"
        cwd "/srv/rabbitmq"
	user "rabbitmq"
        command "/usr/local/sbin/rabbitmqctl set_permissions -p #{vhost} #{user} #{priv}"
      end
    end
  end

  file "/srv/rabbitmq/delete_me_to_update_perms"
end

