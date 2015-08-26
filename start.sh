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
fi

# attach to running container if possible, or spawn a new one
DEVDOCKER_ID="$(docker ps | grep "\<$DEVDOCKER_IMAGE\>" | head -n 1 | awk '{print $1}')"
if [ "$DEVDOCKER_ID" == "" ]; then
    # get latest image from local repository
    echo
    if [ "$DEVDOCKER_AUTOUPDATE" == "1" ]; then
        docker pull "$DEVDOCKER_IMAGE" | grep -v ': Already exists$'
    fi
    DEVDOCKER_ID="$(docker run -d -i \
        -p 80:80 \
        -p 443:443 \
        -p 3306:3306 \
        -e "MYSQL_FORCED_ROOT_PASSWORD=$MYSQL_FORCED_ROOT_PASSWORD" \
        -v "$SSH_DIR:/root/.ssh-readonly:ro" \
        -v "$DOCKERSITE_ROOT/www:/var/www/html" \
        -v "$DOCKERSITE_ROOT/database:/var/lib/mysql" \
        -v "$DOCKERSITE_ROOT/vhosts:/etc/apache2/vhosts" \
        -v "$DOCKERSITE_ROOT/log:/var/log/dockersite" \
        -v "$DOCKERSITE_ROOT/conf-sitesync:/sitesync/etc" \
        "$DEVDOCKER_IMAGE")"
    echo "Attaching to freshly started container $DEVDOCKER_ID"
else
    echo "Attaching to already running container $DEVDOCKER_ID"
fi
docker exec -i -t "$DEVDOCKER_ID" bash
