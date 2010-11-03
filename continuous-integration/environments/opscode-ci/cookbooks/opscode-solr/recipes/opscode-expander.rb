node.set[:opscode_expander_workers] = 2

directory("/srv/opscode-expander") do
  owner "opscode"
  group "opscode"
  mode  "0755"
end

git("/srv/opscode-expander") do
  revision    "master"
  repository  "git@github.com:opscode/opscode-expander.git"
  action      :sync
  user        "opscode"
  group       "opscode"
end

execute("git_reset_opscode_expander") do
  command "git reset --hard"
  user    "opscode"
  group   "opscode"
  cwd     "/srv/opscode-expander"
  action  :nothing
end

template("opscode_expander_config") do
  path    "/srv/opscode-expander/conf/opscode-expander.rb"
  source  "opscode-expander-config.rb.erb"
  owner   "opscode"
  group   "opscode"
  mode    "644"
  variables :rabbitmq_host      => 'localhost',
            :rabbitmq_user      => "chef",
            :rabbitmq_password  => node["apps"]["rabbitmq"]["users"]["chef"],
            :rabbitmq_vhost     => "/chef",
            :opscode_expander_ps_tag => ''
end

execute("update_opscode_expander_gem_bundle") do
  user    "opscode"
  group   "opscode"
  command "bundle install --deployment"
  action  :nothing
  cwd     "/srv/opscode-expander"
end

runit_service "opscode-expander"

source_code_update = resources(:git => '/srv/opscode-expander')
source_code_update.notifies(:run, resources(:execute => "git_reset_opscode_expander"))
source_code_update.notifies(:run, resources(:execute => "update_opscode_expander_gem_bundle"))
source_code_update.notifies(:restart, resources(:service => "opscode-expander"))

config_update = resources(:template => "opscode_expander_config")
config_update.notifies(:restart, resources(:service => "opscode-expander"))
