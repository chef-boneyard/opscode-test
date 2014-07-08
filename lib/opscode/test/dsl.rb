######################################################################
# the dsl module
######################################################################

require 'openssl'
require 'restclient'
require 'json'
require 'opscode/test/database_helper'
require 'opscode/test/logger'
require 'opscode/test/models/superuser'

module Opscode::Test
  module DSL

    include Opscode::Test::Configurable
    include Opscode::Test::DatabaseHelper
    include Opscode::Test::Loggable

    GLOBAL_PLACEHOLDER_ORG_ID = "00000000000000000000000000000000"

    #
    # user-related dsl
    #
    def superuser
      log "Creating the superuser..."
      su = Opscode::Test::Models::Superuser.new
      yield su
      su.create
    end

    def fetch_superuser_cert
      common_name = "URI:http://opscode.com/GUIDS/fu"
      response = JSON.parse(RestClient.post "http://localhost:5140/certificates", :common_name => common_name)

      cert = OpenSSL::X509::Certificate.new(response["cert"])
      key = OpenSSL::PKey::RSA.new(response["keypair"])

      File.open(config.superuser_cert, "w") {|f| f.print(cert)}
      File.open(config.superuser_key, "w") {|f| f.print(key)}
    end

    def superuser_cert
      cert_file = File.read(config.superuser_cert)
      OpenSSL::X509::Certificate.new(cert_file)
    end

    def superuser_key
      key_file = File.read(config.superuser_key)
      OpenSSL::PKey::RSA.new(key_file)
    end

    #
    # general use methods
    # TODO: some of these probably shouldn't be here and we should
    # consider moving this out to a separate module
    #
    def create_credentials_dir
      log "Creating the credentials directory..."
      unless Dir.exists?(config.output_directory)
        Dir.mkdir(config.output_directory)
      end
    end

    def truncate_sql_tables
      log "Truncating the sql tables..."
      db[:users].truncate
    end

    def delete_couchdb_databases
      log "main couchdb databases", :detail
      couchdb_databases = %w{
        opscode_account
        opscode_account_integration
        opscode_account_internal
        opscode_account_internal_integration
        test_harness_setup
        jobs
        jobs_spec
      }

      couchdb_databases.each do |name|
        begin
          couchdb_database(name).delete!
        rescue RestClient::ResourceNotFound; end
      end
    end

    def create_couchdb_databases
      log "Creating the coudhdb databases..."

      # create the account databases
      log "creating main couchdb databases", :detail
      couchdb_databases = %w{
        opscode_account
        opscode_account_internal
      }

      couchdb_databases.each do |name|
        couchdb_database(name).create!
      end
    end

    def create_global_containers(superuser_authz_id)
      log "Creating the global containers..."
      acct_database = couchdb_database('opscode_account')

      %w(organizations users).each do |name|
        container = {
          :containername => name,
          :containerpath => name,
          :requester_id  => superuser_authz_id
        }

        # create model and create container in couchDB
        model = Mixlib::Authorization::Models::Container.on(acct_database).new(container)
        model.save

        # TODO
        # IMPORTANT: We are relying on Mixlib:Auth to make the ACL magic happen, when we replace
        # that library, we need to make sure that we create the proper ACLs here (since we are just
        # throwing it into SQL below).
        #
        # Create container in SQL also (since the contents will never change
        # we can create in both places while we migrate off of couchDB. Once
        # we have finished migrations we can get rid of the couch insert).
        created_time = Time.now.utc
        db[:containers].insert(:name => name, :id => model.id, :org_id => GLOBAL_PLACEHOLDER_ORG_ID, :last_updated_by => model.requester_id, :authz_id => model.authz_id, :created_at => created_time.to_s[0..18], :updated_at => created_time.to_s[0..18])
      end
    end
  end
end
