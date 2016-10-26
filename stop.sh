#!/usr/bin/env bash

BASE_PATH="$(dirname "$0")"
source $BASE_PATH/inc/init

# checking if docker VM is running ($DEVDOCKER_VM)
if [ -x "$DOCKERMACHINE_PATH" ]; then
    if [ "$("$DOCKERMACHINE" status $DEVDOCKER_VM 2>&1)" != "Running" ]; then
        echo -ne "\033$TERM_COLOR_YELLOW"
        echo "# Already stopped"
        echo -ne "\033$TERM_COLOR_NORMAL"
        exit
    fi
    # setting environment variables
    source $BASE_PATH/inc/vm-eval
    eval "$DOCKER_ENV_VARS"
fi

DEVDOCKER_IDS="$(docker ps | (grep "\<$DEVDOCKER_IMAGE\>" || true) | awk '{print $1}')"
if [ "$DEVDOCKER_IDS" == "" ]; then
    echo -ne "\033$TERM_COLOR_YELLOW"
    echo "# All devdocker containers are already stopped"
    echo -ne "\033$TERM_COLOR_NORMAL"
else
    echo -ne "\033$TERM_COLOR_GREEN"
    echo "# Stopping devdocker containers:"
    echo -ne "\033$TERM_COLOR_NORMAL"
    docker stop "$DEVDOCKER_IDS"
fi

# cleanup exited devdocker containers
docker ps -a -q --filter "ancestor=$DEVDOCKER_REPOSITORY/devdocker" | xargs -n 1 -I {} docker rm {} > /dev/null

if [ -x "$DOCKERMACHINE_PATH" ]; then
    echo
    echo -ne "\033$TERM_COLOR_GREEN"
    echo "# You can stop Docker VM if necessary:"
    echo -ne "\033$TERM_COLOR_NORMAL"
    echo "./vm-stop.sh"
fi
