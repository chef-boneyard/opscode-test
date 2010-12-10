maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs Opscode authz and starts service"
long_description  <<-EOH
Installs authz directly from source.
EOH
version           "0.7"
recipe            "opscode-authz", "Installs Opscode authz from source"
depends           "erlang_binary"
depends           "opscode-base"
depends           "opscode-github"
depends           "runit"
depends           "capistrano"
depends           "unicorn"
