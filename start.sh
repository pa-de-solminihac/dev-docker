#!/usr/bin/env bash

BASE_PATH="$(dirname "$0")"
source $BASE_PATH/inc/init

# run docker-machine VM if necessary
if [ -x "$DOCKERMACHINE_PATH" ]; then
    # ask for root password as early as possible
    if [ -x "$(which sudo 2> /dev/null)" ]; then
        sudo echo -n || exit # ask for root password only once
    fi
    # checking if docker VM is running ($DEVDOCKER_VM)
    if [ "$($DOCKERMACHINE status $DEVDOCKER_VM 2>&1)" != "Running" ]; then
        . ./vm-start.sh
        echo
    fi

    # setting environment variables
    source $BASE_PATH/inc/vm-eval
    eval "$DOCKER_ENV_VARS"
    #env | grep DOCKER
fi

# cleanup exited devdocker containers
docker rm -v $(docker ps --filter status=exited -q 2>/dev/null) 2>/dev/null || true
docker rmi $(docker images --filter dangling=true -q 2>/dev/null) 2>/dev/null || true

# attach to running container if possible, or spawn a new one
DEVDOCKER_ID="$(docker ps | (grep "\<$DEVDOCKER_IMAGE\>" || true) | head -n 1 | awk '{print $1}')"
if [ "$DEVDOCKER_ID" == "" ]; then
    # get latest image from local repository
    if [ "$DEVDOCKER_AUTOUPDATE" == "1" ]; then
        docker pull "$DEVDOCKER_IMAGE" | grep -v ': Already exists$'
    fi
    DEVDOCKER_ID="$(docker run -d -i \
        -p 8022:8022 \
        -p 80:80 \
        -p 443:443 \
        -p 3306:3306 \
        -e "USER_ID=$(id -u)" \
        -e "MYSQL_FORCED_ROOT_PASSWORD=$MYSQL_FORCED_ROOT_PASSWORD" \
        -e "BLACKFIRE_SERVER_ID=$BLACKFIRE_SERVER_ID" \
        -e "BLACKFIRE_SERVER_TOKEN=$BLACKFIRE_SERVER_TOKEN" \
        -e "BLACKFIRE_CLIENT_ID=$BLACKFIRE_CLIENT_ID" \
        -e "BLACKFIRE_CLIENT_TOKEN=$BLACKFIRE_CLIENT_TOKEN" \
        -v "$SSH_DIR:/root/.ssh-readonly:ro" \
        -v "$DOCKERSITE_ROOT/www:/var/www/html" \
        -v "$DOCKERSITE_ROOT/database:/var/lib/mysql" \
        -v "$DOCKERSITE_ROOT/apache2:/etc/apache2/dockersite" \
        -v "$DOCKERSITE_ROOT/log:/var/log/dockersite" \
        -v "$DOCKERSITE_ROOT/conf-sitesync:/sitesync/etc" \
        "$DEVDOCKER_IMAGE")"
    echo -ne "\033$TERM_COLOR_GREEN"
    echo "# Attaching to freshly started container: "
    echo -ne "\033$TERM_COLOR_NORMAL"
    echo $DEVDOCKER_ID
else
    echo -ne "\033$TERM_COLOR_YELLOW"
    echo "# Attaching to already running container: "
    echo -ne "\033$TERM_COLOR_NORMAL"
    echo $DEVDOCKER_ID
fi

# copy /etc/hosts at every startup
ETC_HOSTS="$(cat /etc/hosts)"
docker exec "$DEVDOCKER_ID" sh -c "cat /etc/hosts.ori > /etc/hosts && echo \"$ETC_HOSTS\" >> /etc/hosts"

# attach to container using SSH
# port forwarding reserved ports thanks to ssh
echo
docker exec "$DEVDOCKER_ID" /copy-ssh-config.sh || true
# allow user's own public key
PUBKEY_START="$(cat $SSH_PUBKEY | awk '{print $1}')"
PUBKEY_MID="$(cat $SSH_PUBKEY | awk '{print $2}')"
docker exec "$DEVDOCKER_ID" sh -c "grep -sq \"$PUBKEY_MID\" /root/.ssh/authorized_keys || echo \"$PUBKEY_START $PUBKEY_MID devdocker_owner\" >> /root/.ssh/authorized_keys"
# forwarding ports only if VM is in use and ports are not already forwarded
if [ -x "$DOCKERMACHINE_PATH" ]; then
    if [ -x "$(which sudo 2> /dev/null)" ]; then
        PORT_FW_PID="$(ps auwx | (grep "$SSH_PORT_FW_CMD" | grep -v 'grep' | grep -v 'sudo' || true) | awk '{print $2}')";
        if [ "$PORT_FW_PID" == "" ]; then
            echo -ne "\033$TERM_COLOR_GREEN"
            echo "# Forwarding ports using SSH"
            echo -ne "\033$TERM_COLOR_NORMAL"
            sudo echo -n || exit # ask for root password again if sudo timed out
            # start new port forwarding and connect through ssh
            #sudo $SSH_PORT_FW_CMD &
            SILENCE="$(sudo $SSH_PORT_FW_CMD 2>&1 > /dev/null)" &
        else
            echo -ne "\033$TERM_COLOR_YELLOW"
            echo "# Ports are already forwarded using SSH"
            echo -ne "\033$TERM_COLOR_NORMAL"
        fi
    fi
fi
$SSH_CMD || true
