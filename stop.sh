#!/usr/bin/env bash

BASE_PATH="$(dirname "$0")"
source $BASE_PATH/inc/init

# checking if docker VM is running ($DEVDOCKER_VM)
if [ -x "$DOCKERMACHINE" ];
then
    if [ "$($DOCKERMACHINE --native-ssh status $DEVDOCKER_VM)" != "Running" ]; then
        echo -ne "\033$TERM_COLOR_YELLOW"
        echo "Already stopped"
        echo -ne "\033$TERM_COLOR_NORMAL"
        exit
    fi
    # setting environment variables
    eval "$($DOCKERMACHINE --native-ssh env $DEVDOCKER_VM)"
fi

DEVDOCKER_IDS="$(docker ps | grep "\<$DEVDOCKER_IMAGE\>" | awk '{print $1}')"
if [ "$DEVDOCKER_IDS" == "" ]; then
    echo -ne "\033$TERM_COLOR_YELLOW"
    echo "No running devdocker containers"
    echo -ne "\033$TERM_COLOR_NORMAL"
else
    echo -ne "\033$TERM_COLOR_GREEN"
    echo "Stopping running devdocker containers"
    echo -ne "\033$TERM_COLOR_NORMAL"
    docker stop "$DEVDOCKER_IDS"
fi

echo
echo -ne "\033$TERM_COLOR_GREEN"
echo "You can stop Docker VM if necessary:"
echo -ne "\033$TERM_COLOR_NORMAL"
echo "./vm-stop.sh"
