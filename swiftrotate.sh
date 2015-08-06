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
DATACENTER=$(grep ^DATACENTER $DIR/.swiftrotate | awk -F"=" '{print $2}'|tr -d " ")
REGION=$(grep ^REGION $DIR/.swiftrotate | awk -F"=" '{print $2}'|tr -d " ")
OS_TENANT_ID=$(grep ^OS_TENANT_ID $DIR/.swiftrotate | awk -F "=" '{print $2}'|tr -d " ")
AUTH_URL=$(grep ^AUTH_URL $DIR/.swiftrotate | awk -F"=" '{print $2}'|tr -d " ")
BACKUPDIR=$(grep ^BACKUPDIR $DIR/.swiftrotate | awk -F"=" '{print $2}'|tr -d " ")

# Token is the auth_url plus /tokens
if [ $(echo "$AUTH_URL" | awk '{print substr($0,length,1)}') == '/' ]; 
then
 TOKEN_URL="${AUTH_URL}tokens";
else
 TOKEN_URL="${AUTH_URL}/tokens";
fi;

TENANT_ID=`curl -s -X POST -d "{\"auth\":{\"RAX-KSKEY:apiKeyCredentials\":{\"username\": \"$USERNAME\",\"apiKey\": \"$APIKEY\"}}}" -H 'Content-Type: application/json' $TOKEN_URL|python -mjson.tool|egrep 'tenantId.*Mosso'|head -n 1|perl -pe 's/.*tenantId\".*\"(.*)\"/$1/g'`;
STORAGE_URL=https://snet-storage101.$DATACENTER.clouddrive.com/v1/$TENANT_ID
CONTAINER=syslog

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
    upload -S 5368709120 -c $CONTAINER *.gz 2>/dev/null
    logger -t swiftrotate -p daemon.info "DONE uploading to Swift."
    rm $PIDFILE
fi
