#
# Cookbook Name:: curl
# Recipe:: default
#
# Copyright 2010, Opscode
#
# All rights reserved - Do Not Redistribute
#

%w{curl libcurl4-openssl-dev}.each { |pkg| package pkg }

