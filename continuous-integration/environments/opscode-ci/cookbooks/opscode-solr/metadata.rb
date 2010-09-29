maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs Opscode Solr and starts service"
long_description  <<-EOH
Installs Opscode Solr directly from source.
EOH
version           "0.7.1"
recipe            "opscode-solr", "Installs Opscode Solr from source"
depends           "opscode-base"
depends           "opscode-github"
depends           "runit"
depends           "capistrano"
depends           "java"
