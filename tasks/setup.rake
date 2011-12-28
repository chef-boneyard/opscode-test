require 'tmpdir'
require 'uri'

SUPERUSER = "platform-superuser"
ACCOUNT_URI = "http://localhost:4042"
AUTHORIZATION_URI = 'http://localhost:5959'
CHEF_API_URI = 'http://localhost:9021'

def create_credentials_dir(setup_test = true)
  [PLATFORM_TEST_DIR, OPEN_SOURCE_TEST_DIR].each do |dir|
    next if setup_test == false && dir == OPEN_SOURCE_TEST_DIR
    FileUtils.mkdir_p(dir) unless File.exist?(dir)
  end
end

def create_local_test
  Chef::Log.info("Creating bootstrap user '#{SUPERUSER}'")
  Chef::Log.debug "Tmpdir: #{PLATFORM_TEST_DIR}"
  path = File.join(OPSCODE_PROJECT_DIR, "opscode-account", OPSCODE_PROJECT_SUFFIX, "bin")
  Dir.chdir(path) do
    shell_out!("bundle exec ./account-whacker -c #{PLATFORM_TEST_DIR}/superuser.pem -d #{SUPERUSER} -e platform-cukes-superuser@opscode.com -f PlatformSuperuser -l PlatformCukeSuperuser -m cuker -u #{SUPERUSER} -p p@ssw0rd1")
    Chef::Log.info("Creating global containers")
    shell_out!("./global-containers #{SUPERUSER}")
    output = create_public_user('local-test-user', 'Local', 'Test', 'User', 'Local Test User', 'local-test-user@opscode.com')
    Chef::Log.debug(output)
    output = create_public_org("local-test-org", "Local Test Org", SUPERUSER, "#{PLATFORM_TEST_DIR}/superuser.pem", "local-test-user", "#{PLATFORM_TEST_DIR}/local-test-org-validator.pem")
    Chef::Log.debug(output)
  end
  FileUtils.copy("local-test-client.rb","/etc/chef/client.rb")
end

def create_public_org(org_name, org_fullname, opscode_username, opscode_pkey, customer_username, client_key_path)
  STDOUT.sync = true
  Chef::Log.info("Creating #{org_fullname} organization...")
  result = ""
  waiting = true
  while waiting
    result = `./createorgtool -a #{ACCOUNT_URI} -K "#{client_key_path}" -n "#{org_fullname}" -t Business -g "#{org_name}" -u "#{customer_username}" -p "#{opscode_pkey}" -o "#{opscode_username}"`
    if $?.exitstatus == 53
      Chef::Log.info("...")
      sleep 10
    elsif $?.exitstatus == 0
      Chef::Log.info("Created!")
      waiting = false
    else
      Chef::Log.debug("Error!")
      waiting = false
    end
  end
  result
end

def create_public_user(user_name, first_name, middle_name, last_name, display_name, email)
  Chef::Log.info("Creating user #{user_name}")
  o = shell_out!("bundle exec ./createobjecttool -a '#{ACCOUNT_URI}' -o '#{SUPERUSER}' -p '#{PLATFORM_TEST_DIR}/superuser.pem' -w 'user' -n '#{user_name}' -f '#{first_name}' -m '#{middle_name}' -l '#{last_name}' -d '#{display_name}' -e '#{email}' -k '#{PLATFORM_TEST_DIR}/#{user_name}.pem' -s 'p@ssw0rd1'", :env=>{"DEBUG"=>"true"})
  puts o.format_for_exception if Chef::Log.debug?
end

def replace_platform_client
  STDERR.puts "Copying platform-client.rb to /etc/chef/client.rb"
  FileUtils.copy("platform-client.rb", "/etc/chef/client.rb")
end

def cleanup_replicas
  chef_rest.get_rest('_all_dbs').each { |db| chef_rest.delete_rest("#{db}/") if db =~ /replica/ }
end

def cleanup_chefs
  chef_rest.get_rest('_all_dbs').each do |db|
    begin
      if db =~ /^chef_/
        chef_rest.delete_rest("#{db}/")
      end
    rescue
      STDERR.puts "failed cleanup: #{db}, #{$!.message}"
    end
  end
end

def cleanup_cookbooks
  c = Chef::REST.new("#{CHEF_API_URI}/organizations/clownco", "clownco", "#{PLATFORM_TEST_DIR}/clownco.pem")
  cookbooks = c.get_rest("cookbooks").keys
  cookbooks.each do |cookbook|
    STDERR.puts c.delete_rest("cookbooks/#{cookbook}").inspect
  end
  cleanup_cookbook_tarballs
end

def setup_test_harness
  create_credentials_dir
  truncate_sql_tables
  delete_databases
  cleanup_after_naughty_run
  create_account_databases
  create_organization
  org_db_names = create_chef_databases
  dump_sql_database
  prepare_feature_cookbooks
  create_test_harness_setup_database(org_db_names)
  replication_specs = (%w{authorization opscode_account opscode_account_internal} + org_db_names).map{|source_db| {:source_db => "#{Chef::Config[:couchdb_url]}/#{source_db}",:target_db => "#{Chef::Config[:couchdb_url]}/#{source_db}_integration"}}
  replicate_dbs(replication_specs)
  cleanup_unassigned_orgs
end

def setup_test_harness_no_cookbooks
  create_credentials_dir
  truncate_sql_tables
  delete_databases
  cleanup_after_naughty_run
  create_account_databases
  create_organization
  org_db_names = create_chef_databases
  create_test_harness_setup_database(org_db_names)
  replication_specs = (%w{authorization opscode_account opscode_account_internal} + org_db_names).map{|source_db| {:source_db => "#{Chef::Config[:couchdb_url]}/#{source_db}",:target_db => "#{Chef::Config[:couchdb_url]}/#{source_db}_integration"}}
  replicate_dbs(replication_specs)
  dump_sql_database
  cleanup_unassigned_orgs
end

def chef_rest
  Chef::REST.new(Chef::Config[:couchdb_url], nil, nil)
end

def cleanup_after_naughty_run
  %w{clownco-org-admin.pem clownco-org-validation.pem skynet-org-admin.pem skynet-org-validation.pem cooky.pem superuser.pem}.each do |pem_file|
    if File.exists?(File.join(PLATFORM_TEST_DIR, pem_file))
      File.unlink(File.join(PLATFORM_TEST_DIR,pem_file))
    end
  end
  cleanup_cookbook_tarballs
end

def cleanup_cookbook_tarballs
  fcpath = File.join(OPSCODE_PROJECT_DIR, "chef", OPSCODE_PROJECT_SUFFIX, "features", "data", "cookbooks")
  Dir.chdir(fcpath) do
    Dir[File.join(fcpath, '*.tar.gz')].each do |file|
      File.unlink(file)
    end
  end
end

def delete_databases
  %w{authorization authorization_integration opscode_account opscode_account_integration opscode_account_internal opscode_account_internal_integration test_harness_setup jobs jobs_spec}.each do |db|
    begin
      chef_rest.delete_rest("#{db}/")
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
  replicate_dbs({:source_db=>"#{Chef::Config[:couchdb_url]}/authorization_design_documents", :target_db=>"#{Chef::Config[:couchdb_url]}/authorization"})
  Chef::CouchDB.new(Chef::Config[:couchdb_url], "opscode_account").create_db
  Chef::CouchDB.new(Chef::Config[:couchdb_url], "opscode_account_internal").create_db
end

def create_chef_databases
  %w{clownco skynet}.map do |orgname|
    organization = Mixlib::Authorization::Models::Organization.find(orgname)
    dbname = "chef_" + organization["guid"]
    cdb = Chef::CouchDB.new(Chef::Config[:couchdb_url], dbname)
    cdb.create_db
    cdb.create_id_map
    Chef::Node.create_design_document(cdb)
    Chef::Role.create_design_document(cdb)
    Chef::DataBag.create_design_document(cdb)
    dbname
  end
end

def truncate_sql_tables
  Opscode::Mappers.use_dev_config

  db = Sequel.connect(Opscode::Mappers.connection_string)
  Chef::Log.info "Truncating users table"
  db[:users].truncate
end

def dump_sql_database
  db_name = Chef::Config[:sql_db_name]
  target = "#{PLATFORM_TEST_DIR}/#{db_name}.sql"

  Chef::Log.info "Creating SQL DB Dump"
  uri = URI.parse(Opscode::Mappers.connection_string)
  db = uri.path.split('/')[1]
  puts "Type password '#{uri.password}' if prompted"
  dump_cmd = 
    case uri.scheme
    when /mysql/	  
      "mysqldump -u #{uri.user} -p#{uri.password} -h #{uri.host} -P #{uri.port} --protocol=TCP --databases #{db}"
    when /postgres/
      # ugh, no way to give password on command line for pg_dump?
      "pg_dump -Fc -U #{uri.user} -h #{uri.host} -p #{uri.port} #{db}"
    else
      raise "Cannot determine database from connection string: #{Opscode::Mappers.connection_string}"
    end
  puts "Command: #{dump_cmd}"

  shell_out!("#{dump_cmd} > #{target}")
end


def create_test_harness_setup_database(org_db_names)
  db_names = %w{authorization opscode_account opscode_account_internal}.concat Array(org_db_names)
  CouchRest.new(Chef::Config[:couchdb_url]).database!("test_harness_setup")
  db = CouchRest::Database.new(CouchRest::Server.new(Chef::Config[:couchdb_url]),"test_harness_setup")
  db.save_doc({'_id' => 'dbs_to_replicate', 'source_dbs' => db_names})
end

def create_organization
  Chef::Log.info("Creating bootstrap user '#{SUPERUSER}'")
  Chef::Log.debug "Tmpdir: #{PLATFORM_TEST_DIR}"
  oapath = File.join(OPSCODE_PROJECT_DIR, "opscode-account", OPSCODE_PROJECT_SUFFIX)
  Dir.chdir(oapath) do
    shell_out! "./bin/account-whacker -c #{PLATFORM_TEST_DIR}/superuser.pem -d #{SUPERUSER} -e platform-cukes-superuser@opscode.com -f PlatformSuperuser -l PlatformCukeSuperuser -m cuker -u #{SUPERUSER} -p p@ssw0rd1"
  end

  oapath = File.join(OPSCODE_PROJECT_DIR, "opscode-account", OPSCODE_PROJECT_SUFFIX, "bin")
  Dir.chdir(oapath) do
    Chef::Log.info("Creating global containers")
    output = `./global-containers #{SUPERUSER}`
    Chef::Log.debug(output)

    output = create_public_user('cooky', 'Cooky', 'the', 'Monkey', 'Cooky the Monkey', 'cooky@opscode.com')
    Chef::Log.debug(output)

    output = create_public_user('clownco-org-admin', 'ClowncoOrgAdmin', 'ClowncoOrgAdmin', 'ClowncoOrgAdmin', 'ClowncoOrgAdmin', 'clownco-org-admin@opscode.com')
    Chef::Log.debug(output)

    output = create_public_org("clownco", "Clownco, Inc.", SUPERUSER, "#{PLATFORM_TEST_DIR}/superuser.pem", "clownco-org-admin", "#{PLATFORM_TEST_DIR}/clownco-org-validation.pem")
    Chef::Log.debug(output)

    output = create_public_user('skynet-org-admin', 'SkynetOrgAdmin', 'SkynetOrgAdmin', 'SkynetOrgAdmin', 'SkynetOrgAdmin', 'skynet-org-admin@opscode.com')
    Chef::Log.debug(output)

    output = create_public_org("skynet", "SkynetDotOrg", SUPERUSER, "#{PLATFORM_TEST_DIR}/superuser.pem", "skynet-org-admin", "#{PLATFORM_TEST_DIR}/skynet-org-validation.pem")
    Chef::Log.debug(output)
  end

end

def prepare_feature_cookbooks
  Chef::Log.info "Preparing feature cookbooks"
  fcpath = File.join(OPSCODE_PROJECT_DIR, "chef", OPSCODE_PROJECT_SUFFIX, "features", "data", "cookbooks")

  tmp = Tempfile.new("opscode-test-knife.rb")
  tmp << <<-EOH
    log_level                :info
    log_location             STDOUT
    node_name                'clownco-org-admin'
    client_key               "#{PLATFORM_TEST_DIR}/clownco-org-admin.pem"
    chef_server_url          "#{CHEF_API_URI}/organizations/clownco"
    cache_type               'BasicFile'
    cache_options( :path => '#{ENV['HOME']}/.chef/checksums' )
    cookbook_path            ["#{fcpath}"]
  EOH
  tmp.flush

  Dir.chdir(fcpath) do
    Dir[File.join(fcpath, '*')].each do |dir|
      next unless File.directory?(dir)
      cookbook_name = File.basename(dir)

      # For now, I'm usnig knife to upload the cookbooks. Because we don't have a cookbook uploader class now and I don't want to copy over the big chunk of code to do cookbook upload.
      # When we have a cookbook uploader, we should probably use that to do the upload.
      cmd = "knife cookbook upload #{cookbook_name} -c #{tmp.path}"
      Chef::Log.info(`#{cmd}`)
      Chef::Log.info("Uploaded #{cookbook_name} tarball")
    end
  end
end

def cleanup_unassigned_orgs
  db = CouchRest.new(Chef::Config[:couchdb_url]).database!('opscode_account_internal_integration')
  Mixlib::Authorization::Models::OrganizationInternal.on(db).all.each do |o|
    Mixlib::Authorization::Models::OrganizationInternal.on(db).new(o).destroy
  end
end

task :load_deps do
  require 'bundler'
  Bundler.setup
  require 'opscode/dark_launch'
  require 'pp'
  require 'tmpdir'
  require 'fileutils'
  require 'tempfile'

  require 'rubygems'
  require 'chef'
  require 'chef/config'
  require 'chef/client'
  require 'chef/streaming_cookbook_uploader'
  require 'chef/shell_out'
  require 'chef/mixin/shell_out'
  Chef::Config[:dark_launch_config_filename] = "/etc/opscode/dark_launch_features.json"

  require 'sequel'
  #require 'mysql2'
  require 'opscode/mappers/base'

  include Chef::Mixin::ShellOut

  require 'couchrest'
  # For couchdb manual replication.
  require File.join(OPSCODE_PROJECT_DIR, 'chef', OPSCODE_PROJECT_SUFFIX, 'features', 'support', 'couchdb_replicate')

  Chef::Config[:sql_db_name] = 'opscode_chef'

  couchrest = CouchRest.new(Chef::Config[:couchdb_url])
  couchrest.database!('opscode_account')
  couchrest.default_database = 'opscode_account'

  couchrest_int = CouchRest.new(Chef::Config[:couchdb_url])
  couchrest_int.database!('opscode_account_internal')
  couchrest_int.default_database = 'opscode_account_internal'

  require 'mixlib/authorization'
  Mixlib::Authorization::Config.couchdb_uri = Chef::Config[:couchdb_url]
  Mixlib::Authorization::Config.default_database = couchrest.default_database
  Mixlib::Authorization::Config.internal_database = couchrest_int.default_database
  Mixlib::Authorization::Config.authorization_service_uri = AUTHORIZATION_URI
  Mixlib::Authorization::Config.certificate_service_uri = "http://localhost:5140/certificates"
  require 'mixlib/authorization/auth_join'
  require 'mixlib/authorization/models'

  if ENV["DEBUG"]=="true"
    Chef::Log.level = :debug
  else
    Chef::Log.level = :info
  end
end

namespace :setup do
  desc "Setup the test environment, including creating the organization, users, and uploading the fixture cookbooks"
  task :test =>[:load_deps] do
    setup_test_harness
  end

  desc "Setup the test environment, including creating the organization, users (no feature cookbooks)"
  task :test_nocb =>[:load_deps] do
    setup_test_harness_no_cookbooks
  end

  desc "Prepare local testing by uploading feature cookbooks to ParkPlace"
  task :cookbooks do
    prepare_feature_cookbooks
  end

  desc "Setup for local platform testing"
  task :local_platform do
    cleanup_replicas
    cleanup_chefs
    delete_databases
    create_account_databases
    create_credentials_dir(false)
    create_local_test
  end

end

desc "Charge like a cowboy into the battlefield"
task :leeroy_jenkins do
  Rake::Task['cleanup:cleanup'].execute
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

  desc "Delete cookbooks"
  task :cookbooks do
    cleanup_cookbooks
  end
end

# This makes the setup and cleanup tasks load the required libs
Rake::Task.tasks.select { |t| t.name[/(setup|cleanup|leeroy_jenkins)/] }.each do |t|
  task(t.name => :load_deps)
end
