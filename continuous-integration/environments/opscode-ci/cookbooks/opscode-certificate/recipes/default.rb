#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: opscode-certificate
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
#

include_recipe "erlang_binary"
include_recipe "opscode-base"
include_recipe "opscode-certificate::library"

runit_service "opscode-certificate"

execute "echo cert_shut_down_service" do
  notifies :stop, resources(:service => "opscode-certificate")
  not_if do File.exist?("/srv/opscode-certificate/current/start.sh") end
end

