######################################################################
# the dsl module
######################################################################

require 'opscode/test/models/superuser'

module Opscode::Test
  module DSL

    include Opscode::Test::Configurable
    include Opscode::Test::DatabaseHelper

    #
    # user-related dsl
    #
    def superuser
      su = Opscode::Test::Models::Superuser.new
      yield su
      su.create
    end

    #
    # general use methods
    # TODO: some of these probably shouldn't be here and we should
    # consider moving this out to a separate module
    #
    def create_credentials_dir
      unless Dir.exists?(config.output_directory)
        Dir.mkdir(config.output_directory)
      end
    end

    def truncate_sql_tables
      mysql_db[:users].truncate
    end

    def delete_couchdb_databases
      couchdbauthz_databases = %w{
        authorization
        authorization_integration
      }

      couchdbauthz_databases.each do |name|
        begin
          couchdb_database(:authz, name).delete!
        rescue RestClient::ResourceNotFound; end
      end

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
          couchdb_database(:main, name).delete!
        rescue RestClient::ResourceNotFound; end
      end
    end

    def create_couchdb_databases
      # create the authz databases
      couchdbauthz_databases = %w{
        authorization
      }

      couchdbauthz_databases.each do |name|
        couchdb_database(:authz, name).create!
      end

      # replicate the authz design docs
      authz_db = couchdb_database(:authz, 'authorization')
      replication_body = {
        :target => authz_db.uri,
        :source => 'authorization_design_documents'
      }.to_json
      replication_headers = {
        'Content-Type' => 'application/json'
      }
      RestClient.post("#{couchdb_server(:authz).uri}/_replicate",
                      replication_body,
                      replication_headers)

      # create the account databases
      couchdb_databases = %w{
        opscode_account
        opscode_account_internal
      }

      couchdb_databases.each do |name|
        couchdb_database(:main, name).create!
      end
    end

    def create_global_containers(superuser_authz_id)
      auth_database = couchdb_database(:authz, 'authorization')
      acct_database = couchdb_database(:main, 'opscode_account')

      containersets = auth_database.get('containersets')['global_containerset']
      containersets.each do |name, path|
        container = {
          :containername => name,
          :containerpath => path,
          :requester_id  => superuser_authz_id
        }
        Mixlib::Authorization::Models::Container.on(acct_database).new(container).save
      end
    end
  end
end
