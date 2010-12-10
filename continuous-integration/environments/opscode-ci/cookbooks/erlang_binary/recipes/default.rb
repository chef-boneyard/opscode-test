#
# Cookbook Name:: erlang_binary
# Recipe:: default
#
# Copyright 2010, Opscode, Inc.
#
# All rights reserved - Do Not Redistribute
#

erlang_prereq = ["build-essential", "libssl-dev", "libncurses5-dev"]
erlang_version = "otp_R14B"
# Not sure how this happened, but our 32 bit builds of Erlang have
# erts 5.8.1 and 64 bit has 5.8.1.1
erts_version = node[:kernel][:machine] == "x86_64" ? "5.8.1.1" : "5.8.1"
erlang_tarball_basename = "#{erlang_version}-#{node[:kernel][:machine]}.tar.gz"
erlang_tarball_remote_file = "http://s3.amazonaws.com/opscode-erlang/#{erlang_tarball_basename}"
erlang_tarball =  "/tmp/#{erlang_tarball_basename}"
erlang_install_basedir = "/usr/local/lib"
erlang_install_bindir = "/usr/local/bin"

# install pre-requisites
erlang_prereq.each do |n|
  apt_package n do
    action :install
  end
end

directory erlang_install_basedir do
  owner "root"
  mode 0755
  action :create
  not_if "test -d #{erlang_install_basedir}"
end

directory erlang_install_bindir do
  owner "root"
  mode 0755
  action :create
  not_if "test -d #{erlang_install_bindir}"
end

remote_file erlang_tarball do
  source erlang_tarball_remote_file
  action :create_if_missing
end

execute "erlang-unpack" do
  cwd erlang_install_basedir
  command "tar zxvf #{erlang_tarball}"
  not_if "test -d #{erlang_install_basedir}/erlang/lib/erts-#{erts_version}"
end

link "#{erlang_install_bindir}/erl" do
  to "#{erlang_install_basedir}/erlang/bin/erl"
end
link "#{erlang_install_bindir}/erlc" do 
  to "#{erlang_install_basedir}/erlang/bin/erlc" 
end
link "#{erlang_install_bindir}/epmd" do
  to "#{erlang_install_basedir}/erlang/bin/epmd"
end
link "#{erlang_install_bindir}/run_erl" do
  to "#{erlang_install_basedir}/erlang/bin/run_erl"
end
link "#{erlang_install_bindir}/dialyzer" do
  to "#{erlang_install_basedir}/erlang/bin/dialyzer"
end
link "#{erlang_install_bindir}/escript" do
  to "#{erlang_install_basedir}/erlang/bin/escript"
end
link "#{erlang_install_bindir}/run_test" do
  to "#{erlang_install_basedir}/erlang/bin/run_test"
end


