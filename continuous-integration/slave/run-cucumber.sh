#!/bin/bash

# - First argument is path within /srv to run, i.e. the project.
#   All other arguments are passed to cucumber.
# - If --oss-against-platform is passed in, we execute cucumber
#   with the default steps/features disabled, then pass in the
#   bundled chef 

STARTING_PWD="$PWD"

export GEM_HOME=/srv/localgems
export GEM_PATH=/srv/localgems
export PATH=/srv/localgems/bin:$PATH

# restart couchdb to (hopefully) mitigate the replication issues
# (e.g., opscode-account does many replicates and eventually causes
# Couch to start misbehaving)
echo "Restarting couchdb:"
/etc/init.d/couchdb restart

# Kill any lingering couchjs processes
echo "Existing couchjs processes:"
ps uxaw | grep couchjs | grep -v grep
killall couchjs

# Try the standard /srv/.../current directory then the one without
# .../current. If neither are found, print an error and bomb out.
if [ -d "/srv/$1/current" ]; then
    cd /srv/"$1"/current
elif [ -d "/srv/$1" ]; then
    cd /srv/"$1"
else
    echo Cannot find directory in /srv for project: $1 1>&2
    exit 1
fi    
shift

# Remove all the junit output files first so no stale results are
# around at the end of the tests.
echo "Removing stale JUnit output files:"
rm -f "$STARTING_PWD/junit_output/"*

# If --oss-against-platform is passed in as the first argument, set up
# the cucumber arguments to use the bundled chef steps and features.
if [ "$1" = "--oss-against-platform" ]; then
    CHEF_BUNDLED_DIR=`bundle show chef`
    OSS_AGAINST_PLATFORM="-P -r features/support -r features/oss-support -r $CHEF_BUNDLED_DIR/features/steps $CHEF_BUNDLED_DIR/features"
    echo "Using bundled chef in $CHEF_BUNDLED_DIR..."

    # Eat the option argument
    shift
else
    OSS_AGAINST_PLATFORM=""
fi

# Execute cucumber.
if [ -f Gemfile.lock ]; then
  echo RUN: bundle exec cucumber $OSS_AGAINST_PLATFORM "$@" --format junit --out "$STARTING_PWD/junit_output" --format pretty
  bundle exec cucumber $OSS_AGAINST_PLATFORM "$@" --format junit --out "$STARTING_PWD/junit_output" --format pretty
else
  echo RUN: cucumber "$@" --format junit --out "$STARTING_PWD/junit_output" --format pretty
  cucumber "$@" --format junit --out "$STARTING_PWD/junit_output" --format pretty
fi

RESULT=$?

# Touch the mtime of the JUnit output files to work around the fact
# that the NFS server current time may be different than the slave
# current time, which if the times are different enough, causes Hudson
# to ignore all the JUnit output.
ruby /srv/opscode-test/current/continuous-integration/hudson/touch-files.rb "$STARTING_PWD/junit_output/"

# Return with the same error code that cucumber returned.
exit $RESULT

