######################################################################
# the dsl module
######################################################################

require 'opscode/test/models/superuser'

module Opscode::Test
  module DSL

    def superuser
      su = Opscode::Test::Models::Superuser.new
      yield su
      su.create
    end

  end
end
