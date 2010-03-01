#!/bin/env ruby

require 'rubygems'
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

#orgname = ARGV[0]
#admin = ARGV[1]
orgname = "local-test-org"
admin_id = "46ed92a7c593dcb073c8d5ec7c740d24"
#admin_id = Mixlib::Authorization::Models::User.by_username(:key=>"local-test-user").first.fetch_join.auth_object_id
STDERR.puts "admin id: #{admin_id}"
org_database = database_from_orgname(orgname)

o_nodes_query = "curl -s http://#{couchdb_uri}/#{org_database.name}/_design/nodes/_view/all_id"
nodes = JSON.parse(`#{o_nodes_query}`)
STDERR.puts nodes["total_rows"].to_i
if nodes["rows"]
  nodenames = nodes["rows"].map { |node| node["value"]}
  
  nodenames.each do |nodename|
    node_exists = !Mixlib::Authorization::Models::Node.on(org_database).by_name(:key=>nodename).first.nil?
    Mixlib::Authorization::Models::Node.on(org_database).new(:name=>nodename,:requester_id => admin_id, :orgname=>orgname).save unless node_exists
    STDERR.putc('.')
  end
  STDERR.puts "\nnodes done"
end

o_roles_query = "curl -s http://#{couchdb_uri}/#{org_database.name}/_design/roles/_view/all_id"
roles = JSON.parse(`#{o_roles_query}`)
STDERR.puts roles["total_rows"].to_i
if roles["rows"]
  rolenames = roles["rows"].map { |role| role["value"]}
  
  rolenames.each do |rolename|
    role_exists = !Mixlib::Authorization::Models::Role.on(org_database).by_name(:key=>rolename).first.nil?  
    Mixlib::Authorization::Models::Role.on(org_database).new(:name=>rolename,:requester_id => admin_id, :orgname=>orgname).save unless role_exists
    STDERR.putc('.')  
  end
  STDERR.puts "\nroles done"
end

o_cookbooks_query = "curl -s http://#{couchdb_uri}/#{org_database.name}/_design/cookbooks/_view/all_id"
cookbooks = JSON.parse(`#{o_cookbooks_query}`)
STDERR.puts cookbooks["total_rows"].to_i
if cookbooks["rows"]
  cookbooknames = cookbooks["rows"].map { |cookbook| cookbook["value"]}
  
  cookbooknames.each do |cookbookname|
    cookbook_exists = !Mixlib::Authorization::Models::Cookbook.on(org_database).by_name(:key=>cookbookname).first.nil?  
    Mixlib::Authorization::Models::Cookbook.on(org_database).new(:name=>cookbookname,:requester_id => admin_id, :orgname=>orgname).save unless cookbook_exists
    STDERR.putc('.')  
  end
  STDERR.puts "\cookbooks done"
end



# nodes = Mixlib::Authorization::Models::Node.on(org_database).all
# STDERR.puts "Total nodes: #{nodes.length}"
# nodes.each do |node|
#   acl = Mixlib::Authorization::AuthAcl.new(node.fetch_join_acl)
#   ["read","create"].each do |ace|
#     user_ace = acl.aces[ace].to_user(org_database)
#     ["admins","users","clients"].each do |group|
#       user_ace.add_group(group)      
#     end
#     node.update_join_ace(ace, user_ace.to_auth(org_database).ace)
#   end
#   ["delete","update"].each do |ace|
#     user_ace = acl.aces[ace].to_user(org_database)
#     ["admins","users"].each do |group|
#       user_ace.add_group(group)      
#     end
#     node.update_join_ace(ace, user_ace.to_auth(org_database).ace)
#   end
#   STDOUT.putc('.')
# end

# STDERR.puts "\ndone with nodes"

# roles = Mixlib::Authorization::Models::Role.on(org_database).all
# STDERR.puts "Total roles: #{roles.length}"
# roles.each do |role|
#   acl = Mixlib::Authorization::AuthAcl.new(role.fetch_join_acl)
#   ["read"].each do |ace|
#     user_ace = acl.aces[ace].to_user(org_database)
#     ["admins","users","clients"].each do |group|
#       user_ace.add_group(group)
#     end
#     role.update_join_ace(ace, user_ace.to_auth(org_database).ace)
#   end
#   ["create","delete","update"].each do |ace|
#     user_ace = acl.aces[ace].to_user(org_database)
#     ["admins","users"].each do |group|
#       user_ace.add_group(group)
#     end
#     role.update_join_ace(ace, user_ace.to_auth(org_database).ace)
#   end  
#   STDOUT.putc('.')  
# end

# STDERR.puts "\ndone with roles"

# cookbooks = Mixlib::Authorization::Models::Cookbook.on(org_database).all
# STDERR.puts "Total cookbooks: #{cookbooks.length}"
# cookbooks.each do |cookbook|
#   acl = Mixlib::Authorization::AuthAcl.new(cookbook.fetch_join_acl)
#   ["update","read", "delete","create"].each do |ace|
#     user_ace = acl.aces[ace].to_user(org_database)
#     ["admins","users","clients"].each do |group|
#       user_ace.add_group(group)
#     end
#     cookbook.update_join_ace(ace, user_ace.to_auth(org_database).ace)
#     STDOUT.putc('.')
#   end
# end

# STDERR.puts "\ndone with cookbooks"


# data = Mixlib::Authorization::Models::DataBag.on(org_database).all
# STDERR.puts "Total databags: #{data.length}"
# data.each do |data|
#   acl = Mixlib::Authorization::AuthAcl.new(data.fetch_join_acl)
#   ["update","read", "delete","create"].each do |ace|
#     user_ace = acl.aces[ace].to_user(org_database)
#     ["admins","users","clients"].each do |group|
#       user_ace.add_group(group)
#     end
#     data.update_join_ace(ace, user_ace.to_auth(org_database).ace)
#     STDOUT.putc('.')
#   end
# end

# STDERR.puts "\ndone with databags"





