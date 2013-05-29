######################################################################
# config data
######################################################################

require 'mixlib/authorization'

module Opscode::Test

  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield config

    # TODO: this is fucking ugly.
    cdb_server = CouchRest::Server.new("http://#{config.couchdb_host}:#{config.couchdb_port}")
    account_db = CouchRest::Database.new(cdb_server, 'opscode_account')

    Mixlib::Authorization::Config.default_database          = account_db
    Mixlib::Authorization::Config.authorization_service_uri = "http://#{config.bifrost_host}:#{config.bifrost_port}"
    require 'mixlib/authorization/models'
  end

  module Configurable
    def config
      Opscode::Test.config
    end
  end

  class Config

    # config for writable data
    attr_accessor :output_directory

    # config for db
    attr_accessor :db_driver
    attr_accessor :db_host
    attr_accessor :db_user
    attr_accessor :db_password

    # config for couchdb
    attr_accessor :couchdb_host
    attr_accessor :couchdb_port

    # config for couchdbauthz
    attr_accessor :couchdbauthz_host
    attr_accessor :couchdbauthz_port

    # config for authz
    attr_accessor :bifrost_host
    attr_accessor :bifrost_port

    attr_accessor :superuser_cert
    attr_accessor :superuser_key

    def to_s
      return <<-EOS
  output_directory:  #{output_directory}

  db_driver:         #{db_driver}
  db_host:           #{db_host}
  db_user:           #{db_user}
  db_password:       #{db_password}

  couchdb_host:      #{couchdb_host}
  couchdb_port:      #{couchdb_port}

  couchdbauthz_host: #{couchdbauthz_host}
  couchdbauthz_port: #{couchdbauthz_port}

  bifrost_host:        #{bifrost_host}
  bifrost_port:        #{bifrost_port}

  superuser_cert:    #{superuser_cert}
  superuser_key:     #{superuser_key}
EOS
    end
  end
end
