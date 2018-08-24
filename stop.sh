#!/usr/bin/env bash

QUIET="$#"

BASE_PATH="$(dirname "$0")"
cd $BASE_PATH;
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
    echo -n "# All devdocker containers are already stopped"
    echo -ne "\033$TERM_COLOR_NORMAL\n"
else
    echo -ne "\033$TERM_COLOR_GREEN"
    echo -n "# Stopping devdocker containers: "
    echo -ne "\033$TERM_COLOR_NORMAL"
    docker stop "$DEVDOCKER_IDS"
    sleep 1
fi

# cleanup exited devdocker containers
docker ps -a -q --filter "ancestor=$DEVDOCKER_IMAGE" | xargs -n 1 -I {} docker rm {} > /dev/null

if [ -x "$DOCKERMACHINE_PATH" ]; then
    # remove non stopped forwarding ports ssh processes if any
    PORT_FW_PID="$(ps auwx | (grep "$(echo $SSH_PORT_FW_CMD)" | grep -v 'grep' | grep -v 'sudo' || true) | awk '{print $2}')";
    if [ "$PORT_FW_PID" != "" ]; then
        if [[ "$QUIET" == "0" ]]; then
            echo -ne "\033$TERM_COLOR_GREEN"
            echo "# Remove ports forwarding"
            echo -ne "\033$TERM_COLOR_NORMAL"
        fi
        sudo kill -KILL $PORT_FW_PID
    fi
    echo
    echo -ne "\033$TERM_COLOR_GREEN"
    echo "# You can stop Docker VM if necessary: "
    echo -ne "\033$TERM_COLOR_NORMAL"
    echo "./vm-stop.sh"
fi
