#!/usr/bin/env ruby
# Copyright 2010 Opscode, Inc.
# All Rights Reserved - Do Not Distribute
require 'rubygems'
require 'chef/log'
require 'mixlib/authorization'

ACCOUNT_DB_NAME = 'opscode_account'

Mixlib::Authorization::Config.couchdb_uri = 'localhost:5984'
couchrest = CouchRest.new(Mixlib::Authorization::Config.couchdb_uri)
db = couchrest.database!(ACCOUNT_DB_NAME)
couchrest.default_database = ACCOUNT_DB_NAME
Mixlib::Authorization::Config.default_database = db

Mixlib::Authorization::Config.authorization_service_uri ||= 'http://localhost:5959'
Mixlib::Authorization::Config.certificate_service_uri ||= "http://localhost:5140/certificates"

require 'mixlib/authorization/auth_helper'
require 'mixlib/authorization/models'

USAGE =<<-USE
USAGE:
chameleon user regen-key USERNAME
chameleon user reset-password USERNAME
chameleon org regen-key ORGNAME CLIENTNAME
USE

include Mixlib::Authorization::AuthHelper


def print_usage_and_exit
  puts USAGE
  exit(1)
end

def find_user_by_name(user_id)
  begin
    # Find it 
    raise ArgumentError unless u = Mixlib::Authorization::Models::User.by_username(:key => user_id).first
    u
  rescue ArgumentError
    STDERR.puts "FAIL! Could not find a user named '#{user_id}'"
    raise "Failed to find user '#{user_id}'"
  end
end

mode = ARGV.shift
operation = ARGV.shift

case mode
when 'user'
  print_usage_and_exit unless user_id = ARGV.shift
  case operation
  when 'regen-key'
    certificate, key = gen_cert("guid")
    user = find_user_by_name(user_id)
    user.delete(:public_key) # remove old public key field in favor of new certificate [cb]
    user[:certificate] = certificate
    
    # Save it
    Chef::Log.debug("Saving user: #{user.inspect}")
    user.save
    
    print key
    
  when 'reset-password'
    user = find_user_by_name(user_id)
    user.set_password("foo")
    user.save
    puts "user #{user_id}'s password set to 'foo'"
  else
    print_usage_and_exit
  end
when 'org'
  STDERR.puts "Generating a new client key"
  print_usage_and_exit unless operation == "regen-key"
  # Get org and client CLI opts
  print_usage_and_exit unless orgname = ARGV.shift
  STDERR.puts "orgname: #{orgname}"
  print_usage_and_exit unless clientname = ARGV.shift
  STDERR.puts "clientname: #{clientname}"
  
  # Get the ORGDB object and client object
  orgdb = database_from_orgname(orgname)
  raise ArgumentError unless client = Mixlib::Authorization::Models::Client.on(orgdb).by_clientname(:key => clientname).first
  
  certificate, key = gen_cert("guid")
  client[:certificate] = certificate
  
  # SRSLY why do we have to create it again and then save it? can't client remember what its database is?
  client = Mixlib::Authorization::Models::Client.on(orgdb).new(client)
  client.save
  
  client.save
  
  print key
else
  print_usage_and_exit
end
  
  