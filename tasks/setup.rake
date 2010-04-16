require 'fileutils'

PLATFORM_TEST_DIR = '/tmp/opscode-platform-test/'

def create_credentials_dir
  FileUtils.mkdir_p(PLATFORM_TEST_DIR) unless File.exist?(PLATFORM_TEST_DIR)
end

def create_local_test
  path = File.join(OPSCODE_PROJECT_DIR, "opscode-account", "bin")
  Dir.chdir(path) do
    system("./account-whacker -c /tmp/local-test-user.pem -D opscode_account -d local-test-user -e local-test-user@opscode.com -f local -l user  -m test -u local-test-user -p p@ssw0rd1")
    system("./global-containers local-test-user")
    output = create_public_org('local-test-org', 'local-test-org', 'local-test-user', '/tmp/local-test-user.pem', 'local-test-user', '/tmp/local-test-validator.pem')
    Chef::Log.debug(output)
  end
  File.copy("local-test-client.rb","/etc/chef/client.rb")
end

def create_public_org(org_name, org_fullname, opscode_username, opscode_pkey, customer_username, client_key_path)
  STDOUT.sync = true
  Chef::Log.info("Creating #{org_fullname} organization...")
  result = ""
  waiting = true
  while waiting
    result = `./createorgtool -a http://localhost:4042 -K "#{client_key_path}" -n "#{org_fullname}" -t Business -g "#{org_name}" -u "#{customer_username}" -p "#{opscode_pkey}" -o "#{opscode_username}"`
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

def cleanup_cookbooks
  c = Chef::REST.new("http://localhost/organizations/clownco", "clownco", "#{PLATFORM_TEST_DIR}/clownco.pem")
  cookbooks = c.get_rest("cookbooks").keys
  cookbooks.each do |cookbook|
    STDERR.puts c.delete_rest("cookbooks/#{cookbook}").inspect
  end
  cleanup_cookbook_tarballs
end

def setup_test_harness
  create_credentials_dir
  delete_databases
  cleanup_after_naughty_run
  create_account_databases
  create_organization
  org_db_names = create_chef_databases
  prepare_feature_cookbooks
  create_test_harness_setup_database(org_db_names)
  replication_specs = (%w{authorization opscode_account opscode_account_internal} + org_db_names).map{|source_db| {:source_db => source_db,:target_db => "#{source_db}_integration"}}
  replicate_dbs(replication_specs)
end

def replicate_dbs(replication_specs)
  replication_specs = [replication_specs].flatten
  Chef::Log.debug "replication_specs = #{replication_specs.inspect}"
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

  end
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
  fcpath = File.join(OPSCODE_PROJECT_DIR, "opscode-chef", "features", "data", "cookbooks")
  Dir.chdir(fcpath) do
    Dir[File.join(fcpath, '*.tar.gz')].each do |file|
      File.unlink(file)
    end
  end
end

def delete_databases
  c = Chef::REST.new(Chef::Config[:couchdb_url], nil, nil)
  %w{authorization authorization_integration opscode_account opscode_account_integration opscode_account_internal opscode_account_internal_integration test_harness_setup}.each do |db|
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

def create_test_harness_setup_database(org_db_names)
  db_names = %w{authorization opscode_account opscode_account_internal}.concat Array(org_db_names)
  CouchRest.new(Chef::Config[:couchdb_url]).database!("test_harness_setup")
  db = CouchRest::Database.new(CouchRest::Server.new(Chef::Config[:couchdb_url]),"test_harness_setup")
  db.save_doc({'_id' => 'dbs_to_replicate', 'source_dbs' => db_names})
end

def create_organization
  Chef::Log.info("Creating bootstrap user 'platform-superuser'")
  Chef::Log.debug "Tmpdir: #{PLATFORM_TEST_DIR}"
  oapath = File.join(OPSCODE_PROJECT_DIR, "opscode-account")
  Dir.chdir(oapath) do
    begin
      output = `./bin/account-whacker -c #{PLATFORM_TEST_DIR}/superuser.pem -d platform-superuser -e platform-cukes-superuser@opscode.com -f PlatformSuperuser -l PlatformCukeSuperuser -m cuker -u platform-superuser -p p@ssw0rd1`
      Chef::Log.debug(output)
    rescue
      Chef::Log.fatal("I caught #{$!} #{$!.backtrace.join("\n")}")
      raise
    end
  end

  oapath = File.join(OPSCODE_PROJECT_DIR, "opscode-account", "bin")
  Dir.chdir(oapath) do
    Chef::Log.info("Creating global containers")
    output = `./global-containers platform-superuser`
    Chef::Log.debug(output)

    Chef::Log.info("Creating user Cooky")
    output = `./account-whacker -c #{PLATFORM_TEST_DIR}/cooky.pem -d Cooky -e cooky@opscode.com -f Cooky -l Monkey -m the -u cooky -p p@ssw0rd1`
    Chef::Log.debug(output)

    Chef::Log.info "Creating user clownco-org-admin"
    output = `./account-whacker -c #{PLATFORM_TEST_DIR}/clownco-org-admin.pem -d ClowncoOrgAdmin -e clownco-org-admin@opscode.com -f ClowncoOrgAdmin -l ClowncoOrgAdmin -m ClowncoOrgAdmin -u clownco-org-admin -p p@ssw0rd1`
    Chef::Log.debug(output)

    output = create_public_org("clownco", "Clownco, Inc.", "platform-superuser", "#{PLATFORM_TEST_DIR}/superuser.pem", "clownco-org-admin", "#{PLATFORM_TEST_DIR}/clownco-org-validation.pem")
    Chef::Log.debug(output)

    Chef::Log.info "Creating user skynet-org-admin"
    output = `./account-whacker -c #{PLATFORM_TEST_DIR}/skynet-org-admin.pem -d SkynetOrgAdmin -e skynet-org-admin@opscode.com -f SkynetOrgAdmin -l SkynetOrgAdmin -m SkynetOrgAdmin -u skynet-org-admin -p p@ssw0rd1`
    Chef::Log.debug(output)

    output = create_public_org("skynet", "SkynetDotOrg", "platform-superuser", "#{PLATFORM_TEST_DIR}/superuser.pem", "skynet-org-admin", "#{PLATFORM_TEST_DIR}/skynet-org-validation.pem")
    Chef::Log.debug(output)
  end

end

def prepare_feature_cookbooks
  Chef::Log.info "Preparing feature cookbooks"
  fcpath = File.join(OPSCODE_PROJECT_DIR, "opscode-chef", "features", "data", "cookbooks")
  Dir.chdir(fcpath) do
    Dir[File.join(fcpath, '*')].each do |dir|
      next unless File.directory?(dir)
      cookbook_name = File.basename(dir)
      Chef::Log.debug("Creating tarball for #{cookbook_name}")
      `tar zcvf #{cookbook_name}.tar.gz ./#{cookbook_name}`
      Chef::StreamingCookbookUploader.post("http://localhost/organizations/clownco/cookbooks", "clownco-org-admin", "#{PLATFORM_TEST_DIR}/clownco-org-admin.pem", { "name" => cookbook_name, "file" => File.new("#{cookbook_name}.tar.gz") })
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

  desc "Delete cookbooks"
  task :cookbooks do
    cleanup_cookbooks
  end
end
