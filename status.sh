#!/usr/bin/env bash

BASE_PATH="$(dirname "$0")"
source $BASE_PATH/inc/init

# checking if docker VM is running ($DEVDOCKER_VM)
if [ -x "$DOCKERMACHINE_PATH" ]; then
    source $BASE_PATH/vm-status.sh
    echo
fi

DEVDOCKER_CONTAINERS="$(docker ps | (grep "\<$DEVDOCKER_IMAGE\>" || true))"
if [ "$DEVDOCKER_CONTAINERS" == "" ]; then
    echo -ne "\033$TERM_COLOR_YELLOW"
    echo "# All devdocker containers stopped"
    echo -ne "\033$TERM_COLOR_NORMAL"
    exit
fi
echo -ne "\033$TERM_COLOR_GREEN"
echo "# Devdocker containers running:"
echo -ne "\033$TERM_COLOR_NORMAL"
docker ps | head -n 1
echo "$DEVDOCKER_CONTAINERS"

echo
if [ -x "$DOCKERMACHINE" ]; then
    if [ -x "$(which sudo 2> /dev/null)" ]; then
        source $BASE_PATH/inc/vm-eval
        PORT_FW_PID="$(ps auwx | (grep "$SSH_PORT_FW_CMD" | grep -v 'grep' | grep -v 'sudo' || true) | awk '{print $2}')";
        if [ "$PORT_FW_PID" != "" ]; then
            echo -ne "\033$TERM_COLOR_GREEN"
            echo "# Ports are forwarded using SSH"
            echo -ne "\033$TERM_COLOR_NORMAL"
        fi
    fi
fi
