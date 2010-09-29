maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs Opscode Audit and starts service"
long_description  <<-EOH
Installs Audit directly from source.
EOH
version           "0.8"
recipe            "opscode-audit", "Installs Opscode Audit from source"
depends           "opscode-base"
depends           "unicorn"
