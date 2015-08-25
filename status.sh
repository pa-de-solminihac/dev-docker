#!/usr/bin/env bash

BASE_PATH="$(dirname "$0")"
source $BASE_PATH/inc/init

# checking if docker VM is running ($DEVDOCKER_VM)
if [ -x "$DOCKERMACHINE" ];
then
    if [ "$($DOCKERMACHINE --native-ssh status $DEVDOCKER_VM)" != "Running" ]; then
        echo "Docker VM is not running: $DEVDOCKER_VM"
        exit
    fi
    echo "Docker VM is running: $DEVDOCKER_VM"
    $DOCKERMACHINE --native-ssh ip $DEVDOCKER_VM
    # setting environment variables
    eval "$($DOCKERMACHINE --native-ssh env $DEVDOCKER_VM)"
    echo
fi

DEVDOCKER_CONTAINERS="$(docker ps | grep "\<$DEVDOCKER_IMAGE\>")"
if [ "$DEVDOCKER_CONTAINERS" == "" ]; then
    echo "All devdocker containers stopped"
    exit
fi
echo "Devdocker containers running:"
docker ps | head -n 1
echo "$DEVDOCKER_CONTAINERS"
