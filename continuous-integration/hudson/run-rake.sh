#!/bin/bash

# - First argument is path within /srv to run, i.e. the project.
#   All other arguments are passed to cucumber.

STARTING_PWD="$PWD"

export GEM_HOME=/srv/localgems
export GEM_PATH=/srv/localgems
export PATH=/srv/localgems/bin:$PATH

# Try the standard .../current directory then the one without .../current.
# If neither are found, print an error and bomb out.
if [ -d "/srv/$1/current" ]; then
    cd /srv/"$1"/current
elif [ -d "/srv/$1" ]; then
    cd /srv/"$1"
else
    echo Cannot find directory in /srv for project: $1 1>&2
    exit 1
fi    
shift

# make sure the output directory exists..
if [ ! -d "$STARTING_PWD/spec_reports" ]; then
    mkdir "$STARTING_PWD"/spec_reports
fi
# Then tell CI_REPORTER where to stash its files.
export CI_CAPTURE=on
export CI_REPORTS="$STARTING_PWD"/spec_reports

rake -f /srv/localgems/gems/ci_reporter-1.6.2/stub.rake ci:setup:rspec "$@"
RESULT=$?

ruby /srv/opscode-test/current/continuous-integration/hudson/touch-files.rb "$STARTING_PWD/spec_reports/"

# return with the same error code that rake returned.
exit $RESULT

