#!/bin/bash

# This script assumes /srv is mounted already.

# Bootstrap the database for running features tests.
echo "Running opscode-test setup:test"
echo "*******************************"

(cd /srv/opscode-test/current && 
    sudo env GEM_HOME=/srv/localgems GEM_PATH=/srv/localgems PATH=/srv/localgems/bin:$PATH bundle exec rake setup:from_platform &&
    sudo env GEM_HOME=/srv/localgems GEM_PATH=/srv/localgems PATH=/srv/localgems/bin:$PATH bundle exec rake setup:test)

# run hudson slave.
sudo env GEM_HOME=/srv/localgems GEM_PATH=/srv/localgems PATH=/srv/localgems/bin:$PATH java -jar /srv/hudson/slave.jar

