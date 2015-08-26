#!/usr/bin/env bash

BASE_PATH="$(dirname "$0")"
source $BASE_PATH/inc/init

# checking if docker VM is running ($DEVDOCKER_VM)
if [ -x "$DOCKERMACHINE" ];
then
    source $BASE_PATH/vm-status.sh
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
