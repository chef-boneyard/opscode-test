######################################################################
# re-usable things, like couchdb_servers and mysql
######################################################################

require 'sequel'
require 'couchrest'
require 'opscode/test/config'

module Opscode::Test

  def self.database_config
    @database_config ||= DatabaseConfig.new
  end

  class DatabaseConfig

    include Configurable

    attr_reader :db
    attr_reader :couchdb_server
    attr_reader :couchdbauthz_server

    def initialize
      @db = Sequel.connect("#{config.db_driver}://#{config.db_user}:#{config.db_password}@#{config.db_host}/opscode_chef")
      @couchdbauthz_server = CouchRest::Server.new("http://#{config.couchdbauthz_host}:#{config.couchdbauthz_port}")
      @couchdb_server = CouchRest::Server.new("http://#{config.couchdb_host}:#{config.couchdb_port}")
    end

    def couchdb_database(server, name)
      couchdb_server = case server
                       when :authz; @couchdbauthz_server
                       when :main; @couchdb_server
                       end
      CouchRest::Database.new(couchdb_server, name)
    end

    def couchdb_server(server)
      case server
      when :authz; @couchdbauthz_server
      when :main; @couchdb_server
      end
    end

  end
end
