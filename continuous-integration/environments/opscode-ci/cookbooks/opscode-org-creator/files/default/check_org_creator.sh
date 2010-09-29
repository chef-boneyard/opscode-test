#!/bin/bash
#
# evaluate opscode-org-creator status
#
# Date: 2010-04-14
# Author: Nathan Haneysmith <nathan@opscode.com>
#
# the service check is done with following command line:
# /etc/init.d/opscode-org-creator ping

# get status
PING=`/etc/init.d/opscode-org-creator ping`

OUTPUT="org creator status: $PING"

case $PING in
  pong )
    err=0
    ;;
  * )
    err=2
    ;;
esac

if (( $err == 0 )); then
  echo "OK - $OUTPUT"
  exit "$err"
fi

if (( $err == 2 )); then
  echo "CRITICAL - $OUTPUT"
  exit "$err"
fi

echo "no output from plugin"
exit 3

