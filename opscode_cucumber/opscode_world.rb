require 'fileutils'
require 'pp'

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
end

World(OpscodeWorld)
