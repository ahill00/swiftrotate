#!/bin/bash

# Push logs to swift.
# Designed for use with postrotate in logrotate.

# Requirements:
# - A ServiceNet connection to Swift
# -- If you don't want to use ServiceNet, remove "-s" from the swift command.
# - A .swiftrotate file in the same directory.
# See .swiftrotate.example for details on the variable definitions.

PIDFILE="/tmp/swiftrotate.pid"
MYPID=$$
SCRIPT=$0
DIR=$(dirname $SCRIPT)
USERNAME=$(grep ^USERNAME $DIR/.swiftrotate | awk -F"=" '{print $2}'|tr -d " ")
PASSWORD=$(grep ^PASSWORD $DIR/.swiftrotate | awk -F"=" '{print $2}'|tr -d " ")
APIKEY=$(grep ^APIKEY $DIR/.swiftrotate | awk -F"=" '{print $2}'|tr -d " ")
REGION=$(grep ^REGION $DIR/.swiftrotate | awk -F"=" '{print $2}'|tr -d " ")
AUTH_URL=$(grep ^AUTH_URL $DIR/.swiftrotate | awk -F"=" '{print $2}'|tr -d " ")
BACKUPDIR=$(grep ^BACKUPDIR $DIR/.swiftrotate | awk -F"=" '{print $2}'|tr -d " ")
CONTAINER=$(grep ^CONTAINER $DIR/.swiftrotate | awk -F"=" '{print $2}'|tr -d " ")

if [ -f $PIDFILE ]
then
    logger -t swiftrotate -p daemon.info "ERROR: Another swiftrotate process is already running"
else
    echo $MYPID > $PIDFILE
    logger -t swiftrotate -p daemon.info "Uploading to Swift..."
    cd $BACKUPDIR
    /usr/local/bin/swift \
    -v \
    --debug \
    -s --os-endpoint-type=internalURL \
    --auth-version=2.0 --os-auth-url=$AUTH_URL \
    --os-region-name=$REGION \
    -U $USERNAME \
    -K $PASSWORD \
    upload -S 5368709120 -c $CONTAINER *.gz 2>/dev/null
    logger -t swiftrotate -p daemon.info "DONE uploading to Swift."
    rm $PIDFILE
fi
