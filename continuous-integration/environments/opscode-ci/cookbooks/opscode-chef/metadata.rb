maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs Opscode Chef and starts service"
long_description  <<-EOH
Installs Chef Server directly from source.
EOH
version           "0.8.1"
recipe            "opscode-chef", "Installs Opscode Chef from source"
depends           "opscode-base"
depends           "opscode-audit"
depends           "opscode-certificate"
depends           "chef"
