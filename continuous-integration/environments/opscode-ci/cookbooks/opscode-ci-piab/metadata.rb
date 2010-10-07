maintainer       "Opscode"
maintainer_email "ops@opscode.com"
license          "All rights reserved"
description      "Installs/Configures opscode-ci-piab"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.1"

depends 'couchdb'
depends 'opscode-base'
depends 'rabbitmq'
depends 'opscode-solr'
depends 'opscode-certificate'
depends 'opscode-authz'
depends 'opscode-account'
depends 'opscode-chef'

