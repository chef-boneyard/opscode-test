require 'fileutils'
require File.dirname(__FILE__) + "/couchdb_steps"

module Opscode
  extend self
  
  def load_config(*path_chunks)
    Chef::Config.from_file(File.join(File.dirname(__FILE__), '..', 'data', 'config', 'server.rb'))
  end
  
  def setup_logging
    ENV['LOG_LEVEL'] ||= 'error'
    
    if ENV['DEBUG'] == 'true' || ENV['LOG_LEVEL'] == 'debug'
      Chef::Config[:log_level] = :debug
      Chef::Log.level = :debug
    else
      Chef::Config[:log_level] = ENV['LOG_LEVEL'].to_sym 
      Chef::Log.level = ENV['LOG_LEVEL'].to_sym
    end
    Opscode::Audit::Log.logger = Mixlib::Authorization::Log.logger = Ohai::Log.logger = Chef::Log.logger 
  end
  
end

module OpscodeWorld
  
  def stash
    @stash ||= Hash.new
  end
  
  def rest
    @rest ||= Chef::REST.new(Chef::Config[:test_org_request_uri_base], nil, nil)
  end

  def tmpdir
    @tmpdir ||= begin
      dir = File.join(Dir.tmpdir, "chef_integration")
      FileUtils.rm_rf(dir) if File.exist?(dir)
      
      FileUtils.mkdir_p(dir)
      cleanup_dirs << dir
      dir
    end
  end
  
  def cleanup_files
    @cleanup_files ||= Array.new
  end

  def cleanup_dirs
    @cleanup_dirs ||= Array.new
  end
  
end

World(OpscodeWorld)