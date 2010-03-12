module OpscodeWorld
  module REST
    
    def rest
      @rest ||= Chef::REST.new(Chef::Config[:test_org_request_uri_base], nil, nil)
    end

  end
end

World(OpscodeWorld::REST)