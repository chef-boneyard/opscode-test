setup.rb
    Installs all platform components, configures CouchDB/nanite/etc, then runs 
    the feature tests in opscode-account and opscode-chef.
    
bootstrap_couchdb.rb
    Delete all databases from local CouchDB, sets some runtime options, then
    initializes authorization_design_documents with the contents from
    'authorization_design_documents.couchdb-dump'.
    
cmdutil.rb
    Library for script utilities.
    
authorization_design_documents.couchdb-dump
    Backup of authorization_design_documents. Setup.rb uses this to bootstrap the
    local CouchDB database.
    
README.txt
    This file.
