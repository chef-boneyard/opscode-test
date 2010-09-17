#!/bin/bash

# - First argument is path within /srv to run, i.e. the project.
#   All other arguments are passed to cucumber.

STARTING_PWD="$PWD"

export GEM_HOME=/srv/localgems
export GEM_PATH=/srv/localgems
export PATH=/srv/localgems/bin:$PATH

cd /srv/"$1"/current
shift

rake -f /srv/localgems/gems/ci_reporter-1.6.2/stub.rake ci:setup:rspec "$@"
RESULT=$?

mv -v spec/reports/* "$STARTING_PWD"/spec_reports/

# TODO: tim, 2010-9-17: touch output files as otherwise, Hudson complains
# that they are too old. I'm unsure of why.
touch "$STARTING_PWD"/spec_reports/*.xml

# return with the same error code that rake returned.
exit $RESULT

