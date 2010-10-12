maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Starts Chef API service"
long_description  <<-EOH
Starts Chef API service.
EOH
version           "0.8.1"
recipe            "chef-server", "Starts Chef API service"
depends           "unicorn"
depends           "chef"
