maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs Opscode Certificate Service"
long_description  <<-EOH
Installs Cert directly from source.
EOH
version           "0.7"
recipe            "opscode-certificate", "Installs Opscode Certificate service"
depends           "opscode-base"
depends           "opscode-github"
depends           "runit"
depends           "erlang"

