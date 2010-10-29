#!/bin/bash

# This script assumes /srv is mounted already.

# Everything we do from now on uses the /srv-installed GEM's, bins, etc.

# Bootstrap the database.
(cd /srv/opscode-test/current && 
    sudo env GEM_HOME=/srv/localgems GEM_PATH=/srv/localgems PATH=/srv/localgems/bin:$PATH rake setup:from_platform &&
    sudo env GEM_HOME=/srv/localgems GEM_PATH=/srv/localgems PATH=/srv/localgems/bin:$PATH rake setup:test)

# run hudson slave.
sudo env GEM_HOME=/srv/localgems GEM_PATH=/srv/localgems PATH=/srv/localgems/bin:$PATH java -jar /srv/hudson/slave.jar

