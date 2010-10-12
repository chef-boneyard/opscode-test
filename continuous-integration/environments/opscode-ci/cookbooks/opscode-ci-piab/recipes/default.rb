#
# Cookbook Name:: opscode-ci-piab
# Recipe:: default
#
# Copyright 2010, Opscode
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'couchdb'
include_recipe 'opscode-base'
include_recipe 'rabbitmq'
include_recipe 'chef'
include_recipe 'opscode-solr'
include_recipe 'opscode-certificate'
include_recipe 'opscode-authz'
include_recipe 'opscode-account'
include_recipe 'opscode-chef'

# Script to shut down the Hudson slave if the system's been up over a half hour
# and the slave jar isn't running.
if node[:shutdown_idle_hudson_slave] == true
  cookbook_file "/etc/cron.d/shutdown-idle-slave" do
    source "shutdown-idle-slave.cron"
  end
else
  script "remove shutdown-idle-slave cron" do
    interpreter "bash"
    user "root"
    code <<-EOH
      rm -fv /etc/cron.d/shutdown-idle-slave || true
    EOH
  end
end


