maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs Parkplace and starts service"
long_description  <<-EOH
Installs Parkplace directly from Opscode's GIT repository'.
EOH
version           "0.7"
recipe            "parkplace", "Installs Parkplace from Opscode's GIT repository"
depends           "runit"

