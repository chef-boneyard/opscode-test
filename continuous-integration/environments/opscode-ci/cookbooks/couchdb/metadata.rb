maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs CouchDB package and starts service"
long_description  <<-EOH
Installs the CouchDB package if it is available from an package repository on
the node. If the package repository is not available, CouchDB needs to be 
installed via some other method, either a backported package, or compiled 
directly from source.
EOH
version           "0.7"
recipe            "couchdb", "Installs CouchDB 0.9.0 from tarball"
recipe            "couchdb::master", "Installs CouchDB"
depends           "runit"
depends           "erlang_binary"
depends           "build-essential"
depends           "perl"

attribute "couchdb/dir",
  :display_name => "CouchDB Directory",
  :description => "Location for CouchDB configuration",
  :default => "/srv/couchdb/etc/couchdb"

attribute "couchdb/listen_port",
  :display_name => "CouchDB Listen Port",
  :description => "Port that CouchDB should listen on",
  :default => "5984"

attribute "couchdb/listen_ip",
  :display_name => "CouchDB Listen IP",
  :description => "IP address that CouchDB should listen on",
  :default => "0.0.0.0"

