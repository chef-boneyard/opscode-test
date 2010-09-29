maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs Opscode Webui and starts service"
long_description  <<-EOH
Installs Chef Webui directly from source.
EOH
version           "0.8"
recipe            "opscode-webui", "Installs Opscode Webui from source"
depends           "chef"
depends           "opscode-chef"
depends           "opscode-account"
depends           "unicorn"
