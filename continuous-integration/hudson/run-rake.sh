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

mv -v spec/reports "$STARTING_PWD"/spec_reports
