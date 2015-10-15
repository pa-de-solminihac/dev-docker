#!/usr/bin/env bash

BASE_PATH="$(dirname "$0")"
source $BASE_PATH/inc/init

# checking if docker VM is running ($DEVDOCKER_VM)
if [ -x "$DOCKERMACHINE" ]; then
    if [ "$($DOCKERMACHINE --native-ssh status $DEVDOCKER_VM)" != "Running" ]; then
        echo -ne "\033$TERM_COLOR_YELLOW"
        echo "# Docker VM is not running: "
        echo -ne "\033$TERM_COLOR_NORMAL"
        echo "$DEVDOCKER_VM"
        exit
    fi
    echo -ne "\033$TERM_COLOR_GREEN"
    echo "# Docker VM is running: "
    echo -ne "\033$TERM_COLOR_NORMAL"
    echo "$DEVDOCKER_VM"

    # set environment variables
    source $BASE_PATH/inc/vm-eval
    echo "$DOCKERMACHINEIP"
    eval "$DOCKER_ENV_VARS"
    echo
    echo -ne "\033$TERM_COLOR_YELLOW"
    echo "# Run this command to configure your shell:"
    echo -ne "\033$TERM_COLOR_NORMAL"
    echo "eval \"\$($DOCKER_ENV_VARS_CMD)\""

fi
