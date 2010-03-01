#!/usr/bin/env ruby

require 'rubygems'
require 'couchrest'
require 'chef/log'

couchdb_uri = ARGV[0] #'localhost:5984'
couchrest = CouchRest.new(couchdb_uri)
couchrest.database!('opscode_account')
couchrest.default_database = 'opscode_account'

require 'mixlib/authorization'
Mixlib::Authorization::Config.couchdb_uri = couchdb_uri
Mixlib::Authorization::Config.default_database = couchrest.default_database
Mixlib::Authorization::Config.private_key = OpenSSL::PKey::RSA.new(File.read('/etc/opscode/azs.pem'))
Mixlib::Authorization::Config.authorization_service_uri = ARGV[1] #'http://localhost:5959'
Mixlib::Authorization::Config.certificate_service_uri = "http://localhost:5140/certificates"
require 'mixlib/authorization/auth_join'
require 'mixlib/authorization/models'

Mixlib::Authorization::Log.level = :fatal
Mixlib::Authentication::Log.level = :fatal
Chef::Log.level = :fatal

include Mixlib::Authorization::AuthHelper

orgname = ARGV[2]
org_database = database_from_orgname(orgname)

puts "========================="
group = Mixlib::Authorization::Models::Group.on(org_database).by_groupname(:key=>"admins").first
puts Mixlib::Authorization::Models::Group.on(org_database).new(group).save
puts "========================="

