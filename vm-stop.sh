#!/usr/bin/env bash

BASE_PATH="$(dirname "$0")"
source $BASE_PATH/inc/init

# checking if docker VM is running ($DEVDOCKER_VM)
if [ -x "$DOCKERMACHINE_PATH" ]; then
    if [ "$($DOCKERMACHINE status $DEVDOCKER_VM)" != "Running" ]; then
        echo -ne "\033$TERM_COLOR_YELLOW"
        echo "# Docker VM is not running: "
        echo -ne "\033$TERM_COLOR_NORMAL"
        echo $DEVDOCKER_VM
        exit
    fi
    echo -ne "\033$TERM_COLOR_GREEN"
    echo "# Stopping Docker VM (and all containers): "
    echo -ne "\033$TERM_COLOR_NORMAL"
    echo $DEVDOCKER_VM
    # delete port forwarding rules
    VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "tcp-port-8022" > /dev/null 2>&1 || true
    VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "udp-port-8022" > /dev/null 2>&1 || true
    $DOCKERMACHINE stop $DEVDOCKER_VM > /dev/null 2>&1 || true
fi
