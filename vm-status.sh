#!/usr/bin/env bash

BASE_PATH="$(dirname "$0")"
source $BASE_PATH/inc/init

# checking if docker VM is running ($DEVDOCKER_VM)
if [ -x "$DOCKERMACHINE" ];
then
    if [ "$($DOCKERMACHINE --native-ssh status $DEVDOCKER_VM)" != "Running" ]; then
        echo -ne "\033$TERM_COLOR_YELLOW"
        echo -ne "Docker VM is not running: "
        echo -ne "\033$TERM_COLOR_NORMAL"
        echo "$DEVDOCKER_VM"
        exit
    fi
    echo -ne "\033$TERM_COLOR_GREEN"
    echo -ne "Docker VM is running: "
    echo -ne "\033$TERM_COLOR_NORMAL"
    echo "$DEVDOCKER_VM"
    $DOCKERMACHINE --native-ssh ip $DEVDOCKER_VM
    # setting environment variables
    eval "$($DOCKERMACHINE --native-ssh env $DEVDOCKER_VM)"
fi
