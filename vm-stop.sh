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
    VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "tcp-port-80"
    VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "udp-port-80"
    VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "tcp-port-443"
    VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "udp-port-443"
    VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "tcp-port-3306"
    VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "udp-port-3306"
    $DOCKERMACHINE --native-ssh stop $DEVDOCKER_VM
fi
