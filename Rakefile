
gems = %w[chef chef-server-api chef-server-webui chef-server chef-solr]
require 'rubygems'
require 'couchrest'
require 'spec'
require 'tmpdir'
require 'ftools'

%w{chef}.each do |inc_dir|
  $: << File.join(File.dirname(__FILE__), '..', 'opscode-chef', inc_dir, 'lib')
end

require 'chef'
require 'chef/config'
require 'chef/client'
require 'chef/streaming_cookbook_uploader'

couchrest = CouchRest.new(Chef::Config[:couchdb_url])
couchrest.database!('opscode_account')
couchrest.default_database = 'opscode_account'

require 'mixlib/authorization'
Mixlib::Authorization::Config.couchdb_uri = Chef::Config[:couchdb_url]
Mixlib::Authorization::Config.default_database = couchrest.default_database
Mixlib::Authorization::Config.private_key = OpenSSL::PKey::RSA.new(File.read('/etc/opscode/azs.pem'))
Mixlib::Authorization::Config.authorization_service_uri = 'http://localhost:5959'
Mixlib::Authorization::Config.certificate_service_uri = "http://localhost:5140/certificates"
require 'mixlib/authorization/auth_join'
require 'mixlib/authorization/models'

class Chef
  class Config
    test_org_name "clownco"
    test_org_request_uri_base "http://localhost/organizations/#{Chef::Config[:test_org_name]}"
  end 
end

def start_couchdb(type="normal")
  @couchdb_server_pid  = nil
  cid = fork
  if cid
    @couchdb_server_pid = cid
  else
    exec("couchdb")
  end
end

def start_rabbitmq(type="normal")
  @rabbitmq_server_pid = nil
  cid = fork
  if cid
    @rabbitmq_server_pid = cid
  else
    exec("rabbitmq-server")
  end
end

def start_parkplace(type="normal")
  path = File.expand_path(File.join(File.dirname(__FILE__), "..", "parkplace"))
  @parkplace_pid = nil
  cid = fork
  if cid
    @parkplace_pid = cid
  else
    Dir.chdir(path) do
      exec("./bin/parkplace")
    end
  end
end

def start_chef_solr(type="normal")
  path = File.expand_path(File.join(File.dirname(__FILE__), "..", "opscode-chef"))    
  @chef_solr_pid = nil
  cid = fork
  if cid
    @chef_solr_pid = cid
  else
    Dir.chdir(path) do
      case type
      when "normal"
        exec("./chef-solr/bin/chef-solr -l debug")
      when "features"
        exec("./chef-solr/bin/chef-solr -c #{File.join(File.dirname(__FILE__), "features", "data", "config", "server.rb")} -l debug")
      end
    end
  end
end

def start_chef_solr_indexer(type="normal")
  path = File.expand_path(File.join(File.dirname(__FILE__), "..", "opscode-chef"))  
  @chef_solr_indexer = nil
  cid = fork
  if cid
    @chef_solr_indexer_pid = cid
  else
    Dir.chdir(path) do
      case type
      when "normal"
        exec("./chef-solr/bin/chef-solr-indexer -l debug")
      when "features"
        exec("./chef-solr/bin/chef-solr-indexer -c #{File.join(File.dirname(__FILE__), "features", "data", "config", "server.rb")} -l debug")
      end
    end
  end
end

def start_chef_server(type="normal")
  path = File.expand_path(File.join(File.dirname(__FILE__), "..", "opscode-chef"))
  @chef_server_pid = nil
  mcid = fork
  if mcid # parent
    @chef_server_pid = mcid
  else # child
    Dir.chdir(path) do
      case type
      when "normal"
        exec("./chef-server/bin/chef-server -a thin -l debug -N")
      when "features"
        exec("./chef-server/bin/chef-server -a thin -C #{File.join(path, "features", "data", "config", "server.rb")} -l debug -N")
      end
    end
  end
end

def start_certificate(type="normal")
  path = File.expand_path(File.join(File.dirname(__FILE__), "..", "opscode-certificate"))
  @certificate_pid = nil
  cid = fork
  if cid # parent
    @certificate_pid = cid
  else # child
    Dir.chdir(path) do
      exec("slice -N -a thin -p 5140")
    end
  end
end

def start_opscode_audit(type="normal")
  path = File.expand_path(File.join(File.dirname(__FILE__), "..", "opscode-audit"))
  @opscode_audit_pid = nil
  cid = fork
  if cid # parent
    @opscode_audit_pid = cid
  else # child
    Dir.chdir(path) do
      exec("./bin/opscode-audit")
    end
  end
end

def start_opscode_authz(type="normal")
  path = File.expand_path(File.join(File.dirname(__FILE__), "..", "opscode-authz"))
  @opscode_audit_pid = nil
  cid = fork
  if cid # parent
    @opscode_authz_pid = cid
  else # child
    Dir.chdir(path) do
      exec("./start.sh")
    end
  end
end

def start_opscode_account(type="normal")
  path = File.expand_path(File.join(File.dirname(__FILE__), "..", "opscode-account"))
  @opscode_account_pid = nil
  cid = fork
  if cid # parent
    @opscode_account_pid = cid
  else # child
    Dir.chdir(path) do
      exec("slice -a thin -N -p 4042 -l debug")
    end
  end
end

def start_nginx(type="normal")
  path = File.expand_path(File.join(File.dirname(__FILE__), "..", "nginx-sysoev"))
  nginx_pid_file = "/var/run/nginx.pid"
  @nginx_pid = nil
  cid = fork
  if cid # parent
    catch(:done) do
      5.times do
        throw :done if File.exists?(nginx_pid_file) and (@nginx_pid = File.read(nginx_pid_file).to_i)
        sleep 1
      end
    end
    exit(-1) unless @nginx_pid
  else # child
    Dir.chdir(path) do
      exec("./objs/nginx -c #{path}/conf/platform.conf")
    end
  end
end

def create_local_test
  path = File.expand_path(File.join(File.dirname(__FILE__), "..", "opscode-account", "bin"))
  Dir.chdir(path) do
    system("./account-whacker -c /tmp/local-test-user.pem -D opscode_account -d local-test-user -e local-test-user@opscode.com -f local -l user  -m test -u local-test-user")
    system("./global-containers local-test-user")
    system("./bootstraptool -a http://localhost -K /tmp/local-test-validator.pem -d local-test-org -e local-test@opscode.com -f local -k /tmp/local-test-user.pem -l user -m test  -n local-test-org -t Business -g local-test-org -u local-test-user -p /tmp/local-test-user.pem -o local-test-user")
  end
  File.copy("local-test-client.rb","/etc/chef/client.rb")
end

def replace_platform_client
  STDERR.puts "Copying platform-client.rb to /etc/chef/client.rb"
  File.copy("platform-client.rb", "/etc/chef/client.rb")
end

def backup_platform_client
  if File.exists?("platform-client.rb")
    STDERR.puts "platform-client.rb already exists.  Doing nothing"
  else
    File.copy("/etc/chef/client.rb", "platform-client.rb")
  end
end

def cleanup_replicas
  c = Chef::REST.new(Chef::Config[:couchdb_url], nil, nil)
  c.get_rest('_all_dbs').each { |db| c.delete_rest("#{db}/") if db =~ /replica/ }
end

def cleanup_chefs
  c = Chef::REST.new(Chef::Config[:couchdb_url], nil, nil)
  begin
    c.get_rest('_all_dbs').each { |db| c.delete_rest("#{db}/") if db =~ /^chef_/ }
  rescue
    STDERR.puts "failed cleanup: #{db}, #{$!.message}"
  end
end

def setup_test_harness
  delete_databases
  cleanup_after_naughty_run
  create_account_databases
  create_organization
  guid = create_chef_databases
  prepare_feature_cookbooks
  create_test_harness_setup_database(guid)
  replication_specs = ["authorization", "chef_#{guid}", "opscode_account"].map{|source_db| {:source_db => source_db,:target_db => "#{source_db}_integration"}}
  replicate_dbs(replication_specs, true)
end


def replicate_dbs(replication_specs, delete_source_dbs = false)
  replication_specs = [replication_specs].flatten
  Chef::Log.debug "replication_specs = #{replication_specs.inspect}, delete_source_dbs = #{delete_source_dbs}"
  c = Chef::REST.new(Chef::Config[:couchdb_url], nil, nil)
  replication_specs.each do |spec|
    source_db = spec[:source_db]
    target_db = spec[:target_db]
    
    Chef::Log.debug("Deleting #{target_db}, if exists")
    begin
      c.delete_rest("#{target_db}/")
    rescue Net::HTTPServerException => e
      raise unless e.message =~ /Not Found/
    end
    
    Chef::Log.debug("Creating #{target_db}")
    c.put_rest(target_db, nil)
    
    Chef::Log.debug("Replicating #{source_db} to #{target_db}")
    c.post_rest("_replicate", { "source" => "#{Chef::Config[:couchdb_url]}/#{source_db}", "target" => "#{Chef::Config[:couchdb_url]}/#{target_db}" })
    
    if delete_source_dbs
      Chef::Log.debug("Deleting #{source_db}")
      c.delete_rest(source_db)
    end
  end
end

def cleanup_after_naughty_run
  if File.exists?(File.join(Dir.tmpdir, "validation.pem"))
    File.unlink(File.join(Dir.tmpdir, "validation.pem")) 
  end
  if File.exists?(File.join(Dir.tmpdir, "clownco.pem"))
    File.unlink(File.join(Dir.tmpdir, "clownco.pem"))
  end
  fcpath = File.expand_path(File.join(File.dirname(__FILE__), "..", "opscode-chef", "features", "data", "cookbooks"))
  Dir.chdir(fcpath) do
    Dir[File.join(fcpath, '*.tar.gz')].each do |file|
      File.unlink(file)
    end
  end
end

def delete_databases
  c = Chef::REST.new(Chef::Config[:couchdb_url], nil, nil)
  %w{authorization authorization_integration opscode_account opscode_account_integration test_harness_setup}.each do |db|
    begin
      c.delete_rest("#{db}/")
    rescue
    end
  end
  cleanup_replicas
  cleanup_chefs
end

def get_db_list
  CouchRest.new(Chef::Config[:couchdb_url]).database!("test_harness_setup")
  db = CouchRest::Database.new(CouchRest::Server.new(Chef::Config[:couchdb_url]),"test_harness_setup")
  
  doc = db.get('dbs_to_replicate')
  dbs_to_replicate = doc['source_dbs']
end 

def create_account_databases
  Chef::Log.info("Creating bootstrap databases")
  replicate_dbs({:source_db=>"authorization_design_documents", :target_db=>"authorization"})
  Chef::CouchDB.new(Chef::Config[:couchdb_url], "opscode_account").create_db  
end

def create_chef_databases
  organization = Mixlib::Authorization::Models::Organization.find(Chef::Config[:test_org_name])
  guid = organization["guid"]
  cdb = Chef::CouchDB.new(Chef::Config[:couchdb_url], "chef_#{guid.downcase}")
  cdb.create_db
  cdb.create_id_map
  Chef::Node.create_design_document(cdb)
  Chef::Role.create_design_document(cdb)
  Chef::DataBag.create_design_document(cdb)
  Chef::Role.sync_from_disk_to_couchdb(cdb)
  guid.downcase
end 

def create_test_harness_setup_database(guid)
  CouchRest.new(Chef::Config[:couchdb_url]).database!("test_harness_setup")
  db = CouchRest::Database.new(CouchRest::Server.new(Chef::Config[:couchdb_url]),"test_harness_setup")
  db.save_doc({'_id' => 'dbs_to_replicate', 'source_dbs' => ["authorization", "chef_#{guid}", "opscode_account"]})
end 

def create_organization
  Chef::Log.info("Creating bootstrap user")
  Chef::Log.debug "Tmpdir: #{Dir.tmpdir}"
  oapath = File.expand_path(File.join(File.dirname(__FILE__), "..", "opscode-account"))
  Dir.chdir(oapath) do
    begin
      output = `./bin/account-whacker -c #{Dir.tmpdir}/clownco.pem -d Clownco -e clownco@opscode.com -f Clown -l co -m Esquire -u clownco`
      Chef::Log.debug(output)
    rescue
      Chef::Log.fatal("I caught #{$!} #{$!.backtrace.join("\n")}")
      raise
    end
  end
  
  Chef::Log.info("Creating global containers")
  oapath = File.expand_path(File.join(File.dirname(__FILE__), "..", "opscode-account"))
  Dir.chdir(oapath) do
    begin
      output = `./bin/global-containers clownco`
      Chef::Log.debug(output)
    rescue
      Chef::Log.fatal("I caught #{$!} #{$!.backtrace.join("\n")}")
      raise
    end
  end
  
  Chef::Log.info("Creating user Cooky")
  oapath = File.expand_path(File.join(File.dirname(__FILE__), "..", "opscode-account"))
  Dir.chdir(oapath) do
    begin
      output = `./bin/account-whacker -c #{Dir.tmpdir}/cooky.pem -d Cooky -e cooky@opscode.com -f Cooky -l Monkey -m the -u cooky`
      Chef::Log.debug(output)
    rescue
      Chef::Log.fatal("I caught #{$!} #{$!.backtrace.join("\n")}")
    end

    Chef::Log.info("Creating bootstrap organization")
    begin
      output = `./bin/bootstraptool -K "#{Dir.tmpdir}/validation.pem" -n "Clownco, Inc." -t "Business" -g "clownco" -p "#{Dir.tmpdir}/clownco.pem" -o "clownco" -a "http://localhost:4042"`
      Chef::Log.debug(output)
    rescue
      Chef::Log.fatal("Generating organization failed: #{$!} #{$!.backtrace.join("\n")}")
      raise
    end
  end
end

def prepare_feature_cookbooks
  Chef::Log.info "Preparing feature cookbooks"
  fcpath = File.expand_path(File.join(File.dirname(__FILE__), "..", "opscode-chef", "features", "data", "cookbooks"))
  Dir.chdir(fcpath) do
    Dir[File.join(fcpath, '*')].each do |dir|
      next unless File.directory?(dir)
      cookbook_name = File.basename(dir)
      Chef::Log.debug("Creating tarball for #{cookbook_name}")
      output = `tar zcvf #{cookbook_name}.tar.gz ./#{cookbook_name}`
      Chef::Log.debug(output)
      Chef::Log.debug("url: #{Chef::Config[:chef_server_url]}")
      Chef::StreamingCookbookUploader.post("http://localhost/organizations/clownco/cookbooks", "clownco", "#{Dir.tmpdir}/clownco.pem", { "name" => cookbook_name, "file" => File.new("#{cookbook_name}.tar.gz") })
      Chef::Log.debug("Uploaded #{cookbook_name} tarball")
    end
  end
end

def check_platform_files
  if !File.exists?("platform-client.rb")
    STDERR.puts "Please run the 'setup:from_platform' task once before testing to backup platform client files"
    exit -1
  end
end

def start_dev_environment(type="normal")
  start_couchdb(type)
  start_rabbitmq(type)
  start_parkplace(type)
  start_chef_solr(type)
  start_chef_solr_indexer(type)
  start_certificate(type)
  start_opscode_audit(type)
  start_opscode_authz(type)
  start_opscode_account(type)
  start_chef_server(type)
  start_nginx(type)
  puts "Running CouchDB at #{@couchdb_server_pid}"
  puts "Running RabbitMQ at #{@rabbitmq_server_pid}"
  puts "Running ParkPlace at #{@parkplace_pid}"
  puts "Running Chef Solr at #{@chef_solr_pid}"
  puts "Running Chef Solr Indexer at #{@chef_solr_indexer_pid}"
  puts "Running Certificate at #{@certificate_pid}"
  puts "Running Opscode Audit at #{@opscode_audit_pid}"
  puts "Running Opscode Authz at #{@opscode_authz_pid}"
  puts "Running Opscode Account at #{@opscode_account_pid}"
  puts "Running Chef at #{@chef_server_pid}"
  puts "Running nginx at #{@nginx_pid}"  
end

def stop_dev_environment
  if @chef_server_pid
    puts "Stopping Chef"
    Process.kill("KILL", @chef_server_pid)
  end
  if @certificate_pid
    puts "Stopping Certificate"
    Process.kill("KILL", @certificate_pid)
  end
  if @opscode_audit_pid
    puts "Stopping Opscode Audit"
    Process.kill("KILL", @opscode_audit_pid)
  end
  if @opscode_authz_pid
    puts "Stopping Opscode Authz"
    Process.kill("KILL", @opscode_authz_pid)
  end
  if @opscode_account_pid
    puts "Stopping Opscode Account"
    Process.kill("KILL", @opscode_account_pid)
  end
  if @couchdb_server_pid
    puts "Stopping CouchDB"
    Process.kill("KILL", @couchdb_server_pid) 
  end
  if @rabbitmq_server_pid
    puts "Stopping RabbitMQ"
    Process.kill("KILL", @rabbitmq_server_pid) 
  end
  if @chef_solr_pid
    puts "Stopping Chef Solr"
    Process.kill("INT", @chef_solr_pid)
  end
  if @chef_solr_indexer_pid
    puts "Stopping Chef Solr Indexer"
    Process.kill("INT", @chef_solr_indexer_pid)
  end
  if @nginx_pid
    puts "Stopping nginx"
    Process.kill("INT", @nginx_pid)
  end
  puts "Have a nice day!"
end

def wait_for_ctrlc
  puts "Hit CTRL-C to destroy development environment"
  trap("CHLD", "IGNORE")
  trap("INT") do
    stop_dev_environment
    exit 1
  end
  while true
    sleep 10
  end
end

desc "Run a Devel instance of Chef"
task :dev do
  start_dev_environment
  wait_for_ctrlc
end

namespace :dev do  
  desc "Install a test instance of Chef for doing features against"
  task :features do
    start_dev_environment("features")
    wait_for_ctrlc
  end

  namespace :features do
    
    namespace :start do
      desc "Start CouchDB for testing"
      task :couchdb do
        start_couchdb("features")
        wait_for_ctrlc
      end

      desc "Start RabbitMQ for testing"
      task :rabbitmq do
        start_rabbitmq("features")
        wait_for_ctrlc
      end
      
      desc "Start ParkPlace for testing"
      task :parkplace do
        start_parkplace("features")
        wait_for_ctrlc
      end

      desc "Start Chef Solr for testing"
      task :chef_solr do
        start_chef_solr("features")
        wait_for_ctrlc
      end

      desc "Start Chef Solr Indexer for testing"
      task :chef_solr_indexer do
        start_chef_solr_indexer("features")
        wait_for_ctrlc
      end

      desc "Start Chef Server for testing"
      task :chef_server do
        start_chef_server("features")
        wait_for_ctrlc
      end

      desc "Start Certificate for testing"
      task :certificate do
        start_certificate("features")
        wait_for_ctrlc
      end

      desc "Start Opscode Audit for testing"
      task :opscode_audit do
        start_opscode_audit("features")
        wait_for_ctrlc
      end

      desc "Start Opscode Authz for testing"
      task :opscode_authz do
        start_opscode_authz("features")
        wait_for_ctrlc
      end

      desc "Start Opscode Account for testing"
      task :opscode_account do
        start_opscode_account("features")
        wait_for_ctrlc
      end
      
      desc "Start Nginx for testing"
      task :nginx do
        start_nginx("features")
        wait_for_ctrlc
      end
      
    end
  end

  namespace :start do
    desc "Start CouchDB"
    task :couchdb do
      start_couchdb
      wait_for_ctrlc
    end

    desc "Start RabbitMQ"
    task :rabbitmq do
      start_rabbitmq
      wait_for_ctrlc
    end
    
    desc "Start ParkPlace"
    task :parkplace do
      start_parkplace
      wait_for_ctrlc
    end

    desc "Start Chef Solr"
    task :chef_solr do
      start_chef_solr
      wait_for_ctrlc
    end

    desc "Start Chef Solr Indexer"
    task :chef_solr_indexer do
      start_chef_solr_indexer
      wait_for_ctrlc
    end

    desc "Start Chef Server"
    task :chef_server do
      start_chef_server
      wait_for_ctrlc
    end

    desc "Start Certificate"
    task :certificate do
      start_certificate
      wait_for_ctrlc
    end

    desc "Start Opscode Audit"
    task :opscode_audit do
      start_opscode_audit
      wait_for_ctrlc
    end

    desc "Start Opscode Authz"
    task :opscode_authz do
      start_opscode_authz
      wait_for_ctrlc
    end

    desc "Start Opscode Account"
    task :opscode_account do
      start_opscode_account
      wait_for_ctrlc
    end
    
    desc "Start Nginx for testing"
    task :nginx do
      start_nginx
      wait_for_ctrlc
    end
    
  end
end

task :check_platform_files do
  check_platform_files
end

namespace :cleanup do
  desc "Delete all chef integration & replica databases"
  task :cleanup do
    delete_databases
  end

  desc "Delete all replica databases"
  task :replicas do
    cleanup_replicas
  end

  desc "Delete all chef databases"
  task :chefs do
    cleanup_chefs
  end
end

namespace :setup do
  desc "Setup the test environment, including creating the organization, users, and uploading the fixture cookbooks"
  task :test =>[:check_platform_files] do
    setup_test_harness
  end
  
  desc "Prepare local testing by uploading feature cookbooks to ParkPlace"
  task :cookbooks do
    prepare_feature_cookbooks
  end
  
  desc "Backup production platform files so we can safely test locally"
  task :from_platform do
    backup_platform_client
  end
  
  desc "Return production platform files to their places"
  task :to_platform =>[:check_platform_files] do
    replace_platform_client
  end
  
  desc "Setup for local platform testing"
  task :local_platform=>[:check_platform_files] do
    cleanup_replicas
    cleanup_chefs
    delete_databases
    create_account_databases
    create_local_test
  end
end
