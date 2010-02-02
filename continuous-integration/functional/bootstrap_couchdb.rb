#!/usr/bin/env ruby

require 'rubygems'
require 'couchrest'
require 'rest_client'

couchdb_url = "http://localhost:5984"
couchdb_import_filename = ARGV[0] || "authorization_design_documents.couchdb-dump"

if !File.exists?(couchdb_import_filename)
  raise "No such file: #{couchdb_import_filename}, needed for import into CouchDB"
end

couch = CouchRest.new 'http://localhost:5984'

# configure couchdb
# TODO: CouchRest doesn't deal well with CouchDB's results from these PUT's,
# which is the old value that was there (e,g,  "500"\n  -- quotes included),
# so we use RestClient directly.
#CouchRest.put "#{couchdb_url}/_config/couchdb/max_dbs_open", "1000"
RestClient.put "#{couchdb_url}/_config/couchdb/max_dbs_open", '"1000"'
RestClient.put "#{couchdb_url}/_config/query_server_config/reduce_limit", '"false"'

# delete all databases.
databases = couch.databases
databases.each do |dbname|
  puts "Deleting database #{dbname}..."
  db = couch.database dbname
  db.delete!
end

# create authorization_design_documents database
puts "Creating database authorization_design_documents..."
couch.database! "authorization_design_documents"

# import authorization_design_documents using the Python couchdb-load app"
cmd = "couchdb-load #{couchdb_url}/authorization_design_documents < #{couchdb_import_filename}"
puts "Importing authorization_design_documents - running:\n  #{cmd}"
system cmd

