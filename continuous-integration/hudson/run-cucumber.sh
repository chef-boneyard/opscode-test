#!/bin/bash

# - First argument is path within /srv to run, i.e. the project.
#   All other arguments are passed to cucumber.

STARTING_PWD="$PWD"

export GEM_HOME=/srv/localgems
export GEM_PATH=/srv/localgems
export PATH=/srv/localgems/bin:$PATH

cd /srv/"$1"/current
shift

cucumber "$@" --format junit --out "$STARTING_PWD/junit_output"
RESULT=$?

ruby /srv/opscode-test/current/continuous-integration/hudson/touch-files.rb "$STARTING_PWD/junit_output/"

# return with the same error code that cucumber returned.
exit $RESULT

