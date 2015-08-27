#!/usr/bin/env bash

BASE_PATH="$(dirname "$0")"
source $BASE_PATH/inc/init

# run docker-machine VM if necessary
if [ -x "$DOCKERMACHINE" ];
then
    # checking if docker VM is running ($DEVDOCKER_VM)
    if [ "$($DOCKERMACHINE --native-ssh status $DEVDOCKER_VM)" != "Running" ]; then
        . ./vm-start.sh
    fi
    # setting environment variables
    eval "$($DOCKERMACHINE --native-ssh env $DEVDOCKER_VM)"
    #env | grep DOCKER
    echo
fi

# attach to running container if possible, or spawn a new one
DEVDOCKER_ID="$(docker ps | grep "\<$DEVDOCKER_IMAGE\>" | head -n 1 | awk '{print $1}')"
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
        -e "MYSQL_FORCED_ROOT_PASSWORD=$MYSQL_FORCED_ROOT_PASSWORD" \
        -v "$SSH_DIR:/root/.ssh-readonly:ro" \
        -v "$DOCKERSITE_ROOT/www:/var/www/html" \
        -v "$DOCKERSITE_ROOT/database:/var/lib/mysql" \
        -v "$DOCKERSITE_ROOT/vhosts:/etc/apache2/dockersite-vhosts" \
        -v "$DOCKERSITE_ROOT/log:/var/log/dockersite" \
        -v "$DOCKERSITE_ROOT/conf-sitesync:/sitesync/etc" \
        "$DEVDOCKER_IMAGE")"
    echo "Attaching to freshly started container $DEVDOCKER_ID"
else
    echo "Attaching to already running container $DEVDOCKER_ID"
fi

# copy /etc/hosts at every startup
ETC_HOSTS="$(cat /etc/hosts)"
docker exec "$DEVDOCKER_ID" sh -c "cat /etc/hosts.ori > /etc/hosts && echo \"$ETC_HOSTS\" >> /etc/hosts"

# attach to container using SSH
# port forwarding reserved ports thanks to ssh
echo
docker exec "$DEVDOCKER_ID" /copy-ssh-config.sh
# allow user's own public key
PUBKEY_START="$(cat $SSH_PUBKEY | awk '{print $1}')"
PUBKEY_MID="$(cat $SSH_PUBKEY | awk '{print $2}')"
docker exec "$DEVDOCKER_ID" sh -c "grep -sq \"$PUBKEY_MID\" /root/.ssh/authorized_keys || echo \"$PUBKEY_START $PUBKEY_MID devdocker_owner\" >> /root/.ssh/authorized_keys"
echo "Sudoing in order to setup port forwarding (may ask for your root password)"
# forwarding ports only if VM is in use
if [ -x "$DOCKERMACHINE" ]; then
    sudo echo -n # ask for root password only once
    # stop currently running port forwarding
    sudo kill "$(ps auwx | grep "$SSH_PORT_FW_CMD" | grep -v "grep\|sudo" | awk '{print $2}')" > /dev/null 2>&1
    # start new port forwarding and connect through ssh
    sudo $SSH_PORT_FW_CMD -N &
fi
$SSH_CMD
