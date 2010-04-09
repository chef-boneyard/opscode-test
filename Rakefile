require 'pp'
gems = %w[chef chef-server-api chef-server-webui chef-server chef-solr]
require 'rubygems'
require 'couchrest'
require 'spec'
require 'tmpdir'
require 'ftools'

%w{chef}.each do |inc_dir|
  $: << File.join(File.dirname(__FILE__), '..', 'opscode-chef', inc_dir, 'lib')
end

OPSCODE_PROJECT_DIR = File.expand_path(File.dirname(__FILE__) + '/../')
OPCODE_COMMUNITY_PATH = File.expand_path(File.join(File.dirname(__FILE__), "..", "opscode-community-site"))

require 'chef'
require 'chef/config'
require 'chef/client'
require 'chef/streaming_cookbook_uploader'


couchrest = CouchRest.new(Chef::Config[:couchdb_url])
couchrest.database!('opscode_account')
couchrest.default_database = 'opscode_account'

couchrest_int = CouchRest.new(Chef::Config[:couchdb_url])
couchrest_int.database!('opscode_account_internal')
couchrest_int.default_database = 'opscode_account_internal'

require 'mixlib/authorization'
Mixlib::Authorization::Config.couchdb_uri = Chef::Config[:couchdb_url]
Mixlib::Authorization::Config.default_database = couchrest.default_database
Mixlib::Authorization::Config.internal_database = couchrest_int.default_database
Mixlib::Authorization::Config.private_key = OpenSSL::PKey::RSA.new(File.read('/etc/opscode/azs.pem'))
Mixlib::Authorization::Config.authorization_service_uri = 'http://localhost:5959'
Mixlib::Authorization::Config.certificate_service_uri = "http://localhost:5140/certificates"
require 'mixlib/authorization/auth_join'
require 'mixlib/authorization/models'

if ENV["DEBUG"]=="true"
  Chef::Log.level = :debug
else
  Chef::Log.level = :info
end

Dir["tasks/*.rake"].each { |t| load t }
