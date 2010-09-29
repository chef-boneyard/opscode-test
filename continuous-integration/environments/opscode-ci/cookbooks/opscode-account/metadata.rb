maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs Opscode Account and starts service"
long_description  <<-EOH
Installs Account directly from source.
EOH
version           "0.8.1"
recipe            "opscode-account", "Installs Opscode Account from source"
depends           "opscode-base"
depends           "unicorn"
depends           "opscode-chef"
depends           "opscode-audit"
depends           "chef"
