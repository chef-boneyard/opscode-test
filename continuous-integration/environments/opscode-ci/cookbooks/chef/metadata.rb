maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
description       "Installs Open Source Chef gem"
long_description  <<-EOH
Installs Chef gem directly from source.
EOH
version           "0.8"
recipe            "chef", "Installs Opensource Chef from source"
depends           "opscode-base"

