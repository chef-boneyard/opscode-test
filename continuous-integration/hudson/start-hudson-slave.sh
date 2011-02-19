#!/bin/bash

# This script assumes /srv is mounted already.

# Bootstrap the database for running features tests.
(cd /srv/opscode-test/current && 
    sudo bundle update &&
    sudo bundle exec rake setup:from_platform &&
    sudo bundle exec rake setup:test)

# run hudson slave.
sudo env GEM_HOME=/srv/localgems GEM_PATH=/srv/localgems PATH=/srv/localgems/bin:$PATH java -jar /srv/hudson/slave.jar

