######################################################################
# helper module for configurable database params
######################################################################

require 'opscode/test/database_config'

module Opscode::Test
  module DatabaseHelper
    def db
      Opscode::Test.database_config.db
    end

    def couchdb_database(server, name)
      Opscode::Test.database_config.couchdb_database(server, name)
    end

    def couchdb_server(server)
      Opscode::Test.database_config.couchdb_server(server)
    end
  end
end

