#!/usr/bin/env bash

BASE_PATH="$(dirname "$0")"
source $BASE_PATH/inc/init

# checking if docker VM is running ($DEVDOCKER_VM)
if [ -x "$DOCKERMACHINE" ];
then
    if [ "$( $DOCKERMACHINE --native-ssh status $DEVDOCKER_VM )" != "Running" ]; then
        echo "Docker VM is not running"
        exit
    fi
    echo "Stopping Docker VM (and all containers)"
    # delete port forwarding rules
    VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "tcp-port-8022" > /dev/null 2>&1
    VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "udp-port-8022" > /dev/null 2>&1
    $DOCKERMACHINE --native-ssh stop $DEVDOCKER_VM
fi
