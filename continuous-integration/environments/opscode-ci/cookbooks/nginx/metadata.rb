maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
description       "Installs and configures nginx"
long_description  <<-EOH
Installs and configures nginx
EOH
version           "0.7"
recipe            "nginx", "Installs and configures nginx"

depends "opscode-github"
