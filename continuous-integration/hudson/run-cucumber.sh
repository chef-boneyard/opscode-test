#!/bin/bash

# - First argument is path within /srv to run, i.e. the project.
#   All other arguments are passed to cucumber.

STARTING_PWD="$PWD"

export GEM_HOME=/srv/localgems
export GEM_PATH=/srv/localgems
export PATH=/srv/localgems/bin:$PATH

# restart couchdb to (hopefully) mitigate the replication issues (e.g., opscode-account
# does many replicates and eventually causes Couch to start misbehaving)
/etc/init.d/couchdb restart

cd /srv/"$1"/current
shift

if [ -f Gemfile.lock ]; then
  bundle exec cucumber "$@" --format junit --out "$STARTING_PWD/junit_output"
else
  cucumber "$@" --format junit --out "$STARTING_PWD/junit_output"
fi

RESULT=$?

ruby /srv/opscode-test/current/continuous-integration/hudson/touch-files.rb "$STARTING_PWD/junit_output/"

# return with the same error code that cucumber returned.
exit $RESULT

