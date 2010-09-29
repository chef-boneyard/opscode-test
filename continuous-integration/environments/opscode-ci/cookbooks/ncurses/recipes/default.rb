#
# Cookbook Name:: ncurses
# Recipe:: default
#
# Copyright 2010, Opscode
#
# All rights reserved - Do Not Redistribute
#

%w{libncurses5 libncurses5-dev}.each { |pkg| package pkg }
