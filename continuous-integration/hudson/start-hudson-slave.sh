#!/bin/bash

OLD_PWD=$PWD

sudo hostname ubuntu-ci-slave-euca

# run chef with the system GEM's.
sudo chef-client -l debug

# Everything we do from now on uses the /srv-installed GEM's, bins, etc.
export GEM_HOME=/srv/localgems GEM_PATH=/srv/localgems PATH=/srv/localgems/bin:$PATH

# Bootstrap the database.
(cd /srv/opscode-test/current && 
    sudo rake setup:local_platform &&
    sudo rake setup:test)

# run hudson slave.
sudo java -jar slave.jar

