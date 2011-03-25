#!/bin/bash

# This script is run on the slave node; it's executed by Hudson when
# Hudson starts up the slave node. This script assumes /srv is
# mounted already.

# Bootstrap the database for running features tests.
echo "Running opscode-test setup:test"
echo "*******************************"

# Restart opscode-account && opscode-chef to ensure their NAME to GUID
# organization caches are cleared.
(cd /srv/opscode-test/current;
    sudo /etc/init.d/opscode-account restart;
    sudo /etc/init.d/opscode-chef restart;
    sudo bundle exec rake setup:from_platform;
    sudo bundle exec rake setup:test)

# run hudson slave.
sudo env GEM_HOME=/srv/localgems GEM_PATH=/srv/localgems PATH=/srv/localgems/bin:$PATH java -jar /srv/hudson/slave.jar

