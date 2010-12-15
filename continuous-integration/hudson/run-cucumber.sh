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

# Kill any lingering couchjs processes
echo "Existing couchjs processes:"
ps uxaw | grep couchjs | grep -v grep
killall couchjs

# Try the standard .../current directory then the one without .../current.
# If neither are found, print an error and bomb out.
if [ -d "/srv/$1/current" ]; then
    cd /srv/"$1"/current
else if [ -d "/srv/$1" ]; then
    cd /srv/"$1"
else
    echo Cannot find directory in /srv for project: $1 1>&2
    exit 1
end    
shift

# Remove all the junit output files first so no stale results are around.
rm -f "$STARTING_PWD/junit_output/"*

if [ -f Gemfile.lock ]; then
  bundle exec cucumber "$@" --format junit --out "$STARTING_PWD/junit_output" --format pretty
else
  cucumber "$@" --format junit --out "$STARTING_PWD/junit_output" --format pretty
fi

RESULT=$?

# Touch the mtime of the JUnit output files to work around the fact that the
# NFS server current time may be different than the slave current time, which if
# the times are different enough, causes Hudson to ignore all the JUnit output.
ruby /srv/opscode-test/current/continuous-integration/hudson/touch-files.rb "$STARTING_PWD/junit_output/"

# return with the same error code that cucumber returned.
exit $RESULT

