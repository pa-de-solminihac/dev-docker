#!/usr/bin/env bash

BASE_PATH="$(dirname "$0")"
source $BASE_PATH/inc/init

# run docker-machine VM if necessary
if [ -x "$DOCKERMACHINE_PATH" ]; then
    # ask for root password as early as possible
    if [ -x "$(which sudo 2> /dev/null)" ]; then
        sudo echo -n # ask for root password only once
    fi
fi
./stop.sh
echo
./start.sh
