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
    Mixlib::Authorization::Config.authorization_service_uri = "http://#{config.authz_host}:#{config.authz_port}"
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

    # config for mysql
    attr_accessor :mysql_host
    attr_accessor :mysql_user
    attr_accessor :mysql_password

    # config for couchdb
    attr_accessor :couchdb_host
    attr_accessor :couchdb_port

    # config for couchdbauthz
    attr_accessor :couchdbauthz_host
    attr_accessor :couchdbauthz_port

    # config for authz
    attr_accessor :authz_host
    attr_accessor :authz_port

    attr_accessor :superuser_cert
    attr_accessor :superuser_key

    def to_s
      return <<-EOS
  output_directory:  #{output_directory}

  mysql_host:        #{mysql_host}
  mysql_user:        #{mysql_user}
  mysql_password:    #{mysql_password}

  couchdb_host:      #{couchdb_host}
  couchdb_port:      #{couchdb_port}

  couchdbauthz_host: #{couchdbauthz_host}
  couchdbauthz_port: #{couchdbauthz_port}

  authz_host:        #{authz_host}
  authz_port:        #{authz_port}

  superuser_cert:    #{superuser_cert}
  superuser_key:     #{superuser_key}
EOS
    end
  end
end
