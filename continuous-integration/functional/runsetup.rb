#!/usr/bin/env ruby

# Installs and starts all the software for functional/features/integration testing.

# rspec 1.2.9 required. not rspec 1.3.0, as Object.should works differently
# with 'true' now!

class << @self
  require "#{File.dirname(__FILE__)}/cmdutil"
end

# make logs directory if it doesn't exist.
if !File.directory?("logs")
  run "mkdir logs"
end
if !File.directory?("/var/chef")
  run "sudo mkdir /var/chef"
  run "sudo chown bamboo:bamboo /var/chef"
end

branchname = "master"
ARGV.each do |arg|
  if arg =~ /-.*/
    raise "Unknown argument: #{arg}"
  else
    branchname = arg
  end
end


############ Erlang/OTP
# assumes libssl-dev is already installed.
puts
puts "---- Erlang/OTP ----"
git "git@github.com:timh/otp", branchname
if !File.exists? "otp/Makefile"
  Dir.chdir("otp") do |dir|
    run "./otp_build setup"
  end
  make "otp"
end
make_install "otp"


############ COUCHDB
# - assumes libmozjs-dev and libicu-dev are already installed.
# - assumes that 'configure' has already been run and that the directory run 
#   in already has a apache-couchdb-0.10.1 directory --? does it?
puts
puts "---- CouchDB ----"
COUCHDB_DIR = "apache-couchdb-0.10.1"
if !File.exists? "#{COUCHDB_DIR}/Makefile"
  if !File.directory?(COUCHDB_DIR)
    run "tar zxvf #{COUCHDB_DIR}.tar.gz"
  end
  Dir.chdir(COUCHDB_DIR) do |dir|
    run "./configure"
  end
  make COUCHDB_DIR
end
make_install COUCHDB_DIR
run_server "couchdb"
sleep 5
run "ruby #{File.dirname(__FILE__)}/bootstrap_couchdb.rb opscode-test/continuous-integration/functional/authorization_design_documents.couchdb-dump"


############ Checkout and install couchrest
puts
puts "---- opscode/couchrest ----"
git "git@github.com:opscode/couchrest", branchname
rake_install "couchrest"


############ Checkout and install opscode-cucumber
puts
puts "---- opscode/opscode-cucumber ----"
git "git@github.com:opscode/opscode-cucumber", branchname
rake_install "opscode-cucumber"


############ ruby projects to checkout and rake install
# TODO: don't forget that opscode-account's Rakefile has a typo wrt 
# 'opscode-account' vs. 'opscode_account'
puts
puts "---- Install Opscode Ruby Projects ----"
ruby_projs = 
  ["mixlib-log", "mixlib-cli", "mixlib-config", 
   "mixlib-authentication", "mixlib-authorization", 
   "opscode-rest", "ohai"]
ruby_projs.each do |proj|
  puts
  puts "--- RUBY PROJECT #{proj} ---"
  git "git@github.com:opscode/#{proj}", branchname
  rake_install proj
  puts
end



############ Checkout (only) of opscode-chef
puts
puts "---- Checkout opscode-chef ----"
git "git@github.com:opscode/opscode-chef", branchname


############ Checkout and install of chef
puts
puts "---- Checkout and install chef ----"
git "git://github.com/opscode/chef", branchname
rake_install "chef"



############ RabbitMQ
puts
puts "---- RabbitMQ ----"
RABBITMQ_DIR = "rabbitmq-server-1.7.0"
if !File.directory?(RABBITMQ_DIR)
  run "tar zxvf #{RABBITMQ_DIR}.tar.gz"
end
if !File.exists?("#{RABBITMQ_DIR}/Makefile")
  Dir.chdir(RABBITMQ_DIR) do |dir|
    run "./configure"
  end
end
make "rabbitmq-server-1.7.0"
run_server "rabbitmq-server-1.7.0", "scripts/rabbitmq-server"
sleep 5
rabbitmq_cmds =
  ['add_vhost /nanite', 
   'add_user mapper testing', 'add_user nanite testing',
   'set_permissions -p /nanite mapper ".*" ".*" ".*"',
   'set_permissions -p /nanite nanite ".*" ".*" ".*"',
   'add_vhost /chef',
   'add_user chef testing',
   'set_permissions -p /chef chef ".*" ".*" ".*"'
  ]

rabbitmq_cmds.each do |cmd|
  # ignore errors, in case the user/permission/vhost already exists
  # sudo, in case the erlang cookie isn't readable
  run "sudo rabbitmq-server-1.7.0/scripts/rabbitmqctl #{cmd}", true
end


############ Parkplace
puts
puts "---- Parkplace ----"
git "git://github.com/nuoyan/parkplace.git", branchname
# may need to run:
#   ruby setup.rb
#   chmod +x bin/parkplace
run_server "parkplace", "bin/parkplace"


############ opscode-cert-erlang
puts
puts "---- opscode-cert-erlang ----"
git "git@github.com:opscode/opscode-cert-erlang.git", branchname
make "opscode-cert-erlang"
Dir.chdir("opscode-cert-erlang/deps") do |dir|
  make "webmachine"
end
Dir.chdir("opscode-cert-erlang/deps/webmachine/deps") do |dir|
  make "mochiweb"
end
run_server "opscode-cert-erlang", "./start.sh"


############ opscode-org-creator
puts
puts "---- opscode-org-creator ----"
git "git@github.com:opscode/opscode-org-creator.git", branchname
Dir.chdir("opscode-org-creator") do |dir|
  run "make rel"
end
File.open("opscode-org-creator/rel/org_app/etc/app.config", "w") do |config|
  config.puts <<EOC
[
   %% SASL config
   {sasl, [
           {sasl_error_logger, {file, "log/sasl-error.log"}},
           {errlog_type, error},
           {error_logger_mf_dir, "log/sasl"},      % Log directory
           {error_logger_mf_maxbytes, 10485760},   % 10 MB max file size
           {error_logger_mf_maxfiles, 5}           % 5 files max
           ]},
   %% org_app config
   {org_app, [
              {account_couch_db, {"localhost", 5984}},
              {account_database, "opscode_account"},
              {ready_org_database, "opscode_account_internal"},
              {ready_org_design, "Mixlib::Authorization::Models::OrganizationInternal-b55f90b2734082e5524e21cffb2f0c1e"},
              {ready_org_view, "by_state_count"},
              {ready_org_view_attrs, [{include_docs, false}, {key, "unassigned"}]},
              {ready_org_depth, 25},
              {max_workers, 5},
              {org_create_wait, 2000},
              {org_create_splay, 1800},
              {bootstraptool_executable, "/mnt/bamboo-ebs/opscode-account/bin/bootstraptool"},
              {account_service_base_url, "http://localhost:4042"},
              {superuser_name, "platform-superuser"},
              {superuser_key_path, "/tmp/superuser.pem"}
   ]}
  ].
EOC
end
run_server "opscode-org-creator", "rel/org_app/bin/org_app start"


############ opscode-authz
puts
puts "---- opscode-authz ----"
git "git@github.com:opscode/opscode-authz", branchname
make "opscode-authz"
run_server "opscode-authz", "./start.sh"


############ opscode-audit
puts
puts "---- opscode-audit ----"
git "git@github.com:opscode/opscode-audit", branchname
Dir.chdir("opscode-audit") do |dir|
  run "sudo rake"
  run "sudo rake install"
end
run_server "opscode-audit", "bin/opscode-audit"


############ opscode-account
puts
puts "---- opscode-account ----"
git "git@github.com:opscode/opscode-account", branchname
run "sudo mkdir /etc/opscode", true # ignore failure in making the directory, in case it's already there.
run "sudo cp -av opscode-account/lib/opscode-account/azs.pem /etc/opscode"
run "sudo cp -av opscode-account/lib/opscode-account/webui_pub.pem /etc/opscode"
run_server "opscode-account", "bin/opscode-account -p 4042 -l debug"


############ chef_solr
# need to update 'chef' directory with git
puts
puts "---- chef_solr ----"
run_server "chef/chef-solr", "bin/chef-solr -c ../features/data/config/server.rb -l debug"


############ chef_solr_indexer
puts
puts "---- chef_solr_indexer ----"
run_server "chef/chef-solr", "bin/chef-solr-indexer -c ../features/data/config/server.rb -l debug"


############ chef_server
puts
puts "---- chef_server ----"
run_server "opscode-chef/chef-server", "bin/chef-server -C ../features/data/config/server.rb -a thin -l debug -N"


############ nginx
puts
puts "---- nginx ----"
git "git@github.com:opscode/nginx-sysoev", "opscode-deploy"
if !File.exists? "nginx-sysoev/Makefile"
  Dir.chdir("nginx-sysoev") do |dir|
    run "./configure"
  end
end
make "nginx-sysoev"
make_install "nginx-sysoev"
run "sudo cp -a nginx-sysoev/conf/platform.conf /usr/local/nginx/conf"
run_server "nginx-sysoev", "objs/nginx -c ./conf/platform.conf"

