#!/usr/bin/env ruby
# Copyright 2010 Opscode, Inc.
# All Rights Reserved - Do Not Distribute
require 'rubygems'
require 'chef/log'
require 'mixlib/authorization'

Mixlib::Authorization::Config.couchdb_uri = 'localhost:5984'
couchrest = CouchRest.new(Mixlib::Authorization::Config.couchdb_uri)
db = couchrest.database!('opscode_account')
couchrest.default_database = 'opscode_account'
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

mode = ARGV.shift
operation = ARGV.shift

case mode
when 'user'
  print_usage_and_exit unless user_id = ARGV.shift
  case operation
  when 'regen-key'
    begin
      # Find it 
      user = Mixlib::Authorization::Models::User.by_username(:key => user_id).first
    rescue ArgumentError
      raise NotFound, "Failed to find user '#{user_id}'"
    end
    certificate, key = gen_cert("guid")
    
    user.delete(:public_key) # remove old public key field in favor of new certificate [cb]
    user[:certificate] = certificate
    
    # Save it
    Chef::Log.debug("Saving user: #{user.inspect}")
    user.save
    
    print key
    
  when 'reset-password'
    #
  else
    print_usage_and_exit
  end
when 'org'
  #
else
  print_usage_and_exit
end
  
  