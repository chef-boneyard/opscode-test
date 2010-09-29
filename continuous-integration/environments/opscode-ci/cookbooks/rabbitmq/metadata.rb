maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs Rabbitmq-server and starts service"
long_description  <<-EOH
Installs Rabbitmq directly from deb from rabbitmq.com.
EOH
version           "0.7"
recipe            "rabbitmq", "Installs Rabbitmq-server from deb from rabbitmq.com"
depends           "runit"
depends           "erlang"

