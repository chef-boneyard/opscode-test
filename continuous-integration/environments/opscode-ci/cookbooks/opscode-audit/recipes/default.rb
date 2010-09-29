#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Author:: Nuo Yan <nuo@opscode.com>
# Cookbook Name:: opscode-audit
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
#

include_recipe "opscode-base"
include_recipe "opscode-audit::library"

unless FileTest.exists?("/srv/localgems/gems/tinder-1.3.1/README.txt")
  script "install_tinder_local" do
    interpreter "bash"
    user "root"
    code <<-EOH
      export GEM_HOME=/srv/localgems
      export GEM_PATH=/srv/localgems
      export PATH="/srv/localgems/bin:$PATH"
      gem install tinder --version 1.3.1
    EOH
  end
end

runit_service "opscode-audit"
r = resources(:service => "opscode-audit")

execute "echo audit_shut_down_service" do
  notifies :stop, resources(:service => "opscode-audit")
  not_if do File.exist?("/srv/opscode-audit/current/bin/opscode-audit") end
end

env = node["environment"]
audit_servers = [ node ] 

template "/srv/opscode-audit/current/config/opscode-audit.conf" do
  source "opscode-audit.conf.erb"
  owner "opscode"
  group "opscode"
  mode "644"
  variables(
    :amqp_host => audit_servers[0],
    :amqp_user => "guest",
    :amqp_password => "guest",
    :int_lb_dns => env['int-lb-dns']
  )
  notifies :restart, r
end
