#
# Author:: Nathan Haneysmith <nathan@opscode.com>
# Cookbook Name:: opscode-webui
# Recipe:: default
#
# Copyright 2010, Opscode, Inc.
#

include_recipe "opscode-base"
include_recipe "opscode-account::library"
include_recipe "opscode-chef::library"
include_recipe "unicorn"

gems = {
  "merb-param-protection" => '1.1.0',
  "merb-mailer" => '1.1.0',
  "syntax" => nil,
  "coderay" => nil,
  "ruby-openid" => nil
}

gem_dir = Dir['/srv/localgems/gems/*']

gems.each do |name,version|
  unless gem_dir.find{|d|d=~/\/#{name}-/}
    script "install_#{name}_local" do
      interpreter "bash"
      user "root"
        #gem install -i /srv/localgems #{name} #{version.nil? ? '' : "--version #{version}" }
      code <<-EOH
        export GEM_HOME=/srv/localgems
        export GEM_PATH=/srv/localgems
        export PATH="/srv/localgems/bin:$PATH"
        gem install #{name} #{version.nil? ? '' : "--version #{version}" }
      EOH
    end
  end
end

chargify = node["chargify"]
env = node["environment"]

link "/etc/opscode/webui_priv.pem" do
  to "/srv/opscode-chef/current/chef-server-webui/lib/webui_priv.pem"
end

template "/srv/opscode-chef/current/chef-server-webui/config/environments/cucumber.rb" do
  source "opscode-webui-config.rb.erb"
  owner "opscode"
  group "opscode"
  mode "644"
  variables(
    :int_lb_dns => env['int-lb-dns'],
    :community_servername => env['community_servername'],
    :chargify => chargify
  )
end
#
# template "/srv/opscode-chef/current/chef-server-webui/config/environments/#{node[:app_environment]}.rb" do
#   source "opscode-webui-config.rb.erb"
#   owner "opscode"
#   group "opscode"
#   mode "644"
#   variables(
#     :int_lb_dns => env['int-lb-dns'],
#     :community_servername => env['community_servername']
#   )
# end

template "/srv/opscode-chef/current/chef-server-webui/config.ru" do
  source "opscode-webui-config.ru.erb"
  owner "opscode"
  group "opscode"
  mode "644"
end

unicorn_config "/etc/unicorn/opscode-webui.rb" do
  listen 4500 => { :backlog => 1024, :tcp_nodelay => true }
  worker_timeout 3600
  preload_app false
  worker_processes node.cpu.total.to_i * 4
  owner "opscode"
  group "opscode"
  mode "0644"
end

runit_service "opscode-webui"
service = resources(:service => "opscode-webui")
service.subscribes(:restart, resources(:template => "/etc/unicorn/opscode-webui.rb"))
service.subscribes(:restart, resources(:template => "/srv/opscode-chef/current/chef-server-webui/config/environments/cucumber.rb"))
