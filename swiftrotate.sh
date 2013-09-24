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
USERNAME=$(grep ^USERNAME $DIR/.swiftrotate | awk -F" = " '{print $2}')
PASSWORD=$(grep ^PASSWORD $DIR/.swiftrotate | awk -F" = " '{print $2}')
DATACENTER=$(grep ^DATACENTER $DIR/.swiftrotate | awk -F" = " '{print $2}')
REGION=$(grep ^REGION $DIR/.swiftrotate | awk -F" = " '{print $2}')
OS_TENANT_ID=$(grep ^OS_TENANT_ID $DIR/.swiftrotate | awk -F " = " '{print $2}')
AUTH_URL=$(grep ^AUTH_URL $DIR/.swiftrotate | awk -F" = " '{print $2}')
TENANT_ID=`curl -s -X POST $AUTH_URL -d "{\"auth\":{\"passwordCredentials\":{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\" }},\"tenantId\": \"$OS_TENANT_ID\"}" -H "Content-type: application/json" | python -m json.tool | grep tenantId | grep Mosso  | cut -d ":" -f2 | sort | uniq | sed -e s/\"//g  | sed -e "s/ //g"`
STORAGE_URL=https://snet-storage101.$DATACENTER.clouddrive.com/v1/$TENANT_ID
CONTAINER=syslog
BACKUPDIR=/logs/

mkdir -p $BACKUPDIR

if [ -f $PIDFILE ]
then
    logger -t swiftrotate -p daemon.info "ERROR: Another swiftrotate process is already running"
else
    echo $MYPID > $PIDFILE
    logger -t swiftrotate -p daemon.info "Uploading to Swift..."
    cd $BACKUPDIR
    /usr/local/bin/swift \
    --auth-version=2.0 \
    -v -s \
    --os-auth-url=$AUTH_URL \
    --os-username=$USERNAME \
    --os-password=$PASSWORD \
    --os-tenant-id=$TENANT_ID \
    --os-region-name=$REGION \
    --os-service-type=object-store \
    --os-endpoint-type=internalURL \
    upload -S 5368709120 -c $CONTAINER *.gz
    logger -t swiftrotate -p daemon.info "DONE uploading to Swift."
    rm $PIDFILE
fi
