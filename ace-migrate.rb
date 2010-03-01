#!/bin/env ruby

require 'couchrest'
require 'chef/log'

couchdb_uri = 'localhost:5984'
couchrest = CouchRest.new(couchdb_uri)
couchrest.database!('opscode_account')
couchrest.default_database = 'opscode_account'

require 'mixlib/authorization'
Mixlib::Authorization::Config.couchdb_uri = couchdb_uri
Mixlib::Authorization::Config.default_database = couchrest.default_database
Mixlib::Authorization::Config.private_key = OpenSSL::PKey::RSA.new(File.read('/etc/opscode/azs.pem'))
Mixlib::Authorization::Config.authorization_service_uri = 'http://localhost:5959'
Mixlib::Authorization::Config.certificate_service_uri = "http://localhost:5140/certificates"
require 'mixlib/authorization/auth_join'
require 'mixlib/authorization/models'

Mixlib::Authorization::Log.level = :fatal
Mixlib::Authentication::Log.level = :fatal
Chef::Log.level = :fatal

include Mixlib::Authorization::AuthHelper

org_database = database_from_orgname(ARGV[0])

nodes = Mixlib::Authorization::Models::Node.on(org_database).all
STDERR.puts "Total nodes: #{nodes.length}"
nodes.each do |node|
  acl = Mixlib::Authorization::AuthAcl.new(node.fetch_join_acl)
  ["read","create"].each do |ace|
    user_ace = acl.aces[ace].to_user(org_database)
    ["admins","users","clients"].each do |group|
      user_ace.add_group(group)      
    end
    node.update_join_ace(ace, user_ace.to_auth(org_database).ace)
  end
  ["delete","update"].each do |ace|
    user_ace = acl.aces[ace].to_user(org_database)
    ["admins","users"].each do |group|
      user_ace.add_group(group)      
    end
    node.update_join_ace(ace, user_ace.to_auth(org_database).ace)
  end
  STDOUT.putc('.')
end

STDERR.puts "\ndone with nodes"

roles = Mixlib::Authorization::Models::Role.on(org_database).all
STDERR.puts "Total roles: #{roles.length}"
roles.each do |role|
  acl = Mixlib::Authorization::AuthAcl.new(role.fetch_join_acl)
  ["read"].each do |ace|
    user_ace = acl.aces[ace].to_user(org_database)
    ["admins","users","clients"].each do |group|
      user_ace.add_group(group)
    end
    role.update_join_ace(ace, user_ace.to_auth(org_database).ace)
  end
  ["create","delete","update"].each do |ace|
    user_ace = acl.aces[ace].to_user(org_database)
    ["admins","users"].each do |group|
      user_ace.add_group(group)
    end
    role.update_join_ace(ace, user_ace.to_auth(org_database).ace)
  end  
  STDOUT.putc('.')  
end

STDERR.puts "\ndone with roles"

cookbooks = Mixlib::Authorization::Models::Cookbook.on(org_database).all
STDERR.puts "Total cookbooks: #{cookbooks.length}"
cookbooks.each do |cookbook|
  acl = Mixlib::Authorization::AuthAcl.new(cookbook.fetch_join_acl)
  ["update","read", "delete","create"].each do |ace|
    user_ace = acl.aces[ace].to_user(org_database)
    ["admins","users","clients"].each do |group|
      user_ace.add_group(group)
    end
    cookbook.update_join_ace(ace, user_ace.to_auth(org_database).ace)
    STDOUT.putc('.')
  end
end

STDERR.puts "\ndone with cookbooks"


data = Mixlib::Authorization::Models::DataBag.on(org_database).all
STDERR.puts "Total databags: #{data.length}"
data.each do |data|
  acl = Mixlib::Authorization::AuthAcl.new(data.fetch_join_acl)
  ["update","read", "delete","create"].each do |ace|
    user_ace = acl.aces[ace].to_user(org_database)
    ["admins","users","clients"].each do |group|
      user_ace.add_group(group)
    end
    data.update_join_ace(ace, user_ace.to_auth(org_database).ace)
    STDOUT.putc('.')
  end
end

STDERR.puts "\ndone with databags"





