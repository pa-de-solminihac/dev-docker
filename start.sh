#!/usr/bin/env bash
# run in background, attaching a shell

BASE_PATH="$(dirname "$0")"

# usage
function usage() {
    cat <<EOF

    Usage
    =====

    ./run.sh
EOF
}

# chargement du fichier de config
source $BASE_PATH/inc/base-config
if [ ! -f "$BASE_PATH/etc/config" ]; then
    cat <<EOF
    Fichier de configuration non trouvé.
    Vous devez créer un fichier etc/config

    cp sample/config etc/config
EOF
    exit
else
    source $BASE_PATH/etc/config
fi

# run docker-machine VM if necessary
DOCKERMACHINE="$(which docker-machine 2>/dev/null)"
if [ -x "$DOCKERMACHINE" ];
then
    if [ "$($DOCKERMACHINE --native-ssh status $DEVDOCKER_VM)" != "Running" ]; then
        ./vm-start.sh
    fi
fi

# check parameters
if [ "$DOCKERSITE_ROOT" == "" ]; then
    echo
    echo "Error: missing DOCKERSITE_ROOT value or not pointing to a directory $DOCKERSITE_ROOT"
    usage
    exit
fi

if [ "$SSH_DIR" == "" ]; then
    SSH_DIR="$HOME/.ssh"
fi

if [ ! -d "$SSH_DIR" ]; then
    echo
    echo "Error: missing SSH_DIR value or not pointing to a directory $SSH_DIR"
    usage
    exit
fi

# attach to running container if possible, or spawn a new one
DEVDOCKER_ID="$(docker ps | grep "\<$DEVDOCKER_IMAGE\>" | head -n 1 | awk '{print $1}')"
if [ "$DEVDOCKER_ID" == "" ]; then
    # get latest image from local repository
    docker pull "$DEVDOCKER_IMAGE" | grep "^Status: "
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

