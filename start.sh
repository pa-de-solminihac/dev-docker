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

# run boot2docker if necessary
BOOT2DOCKER="$(which boot2docker 2>/dev/null)"
if [ -x "$BOOT2DOCKER" ];
then
    if [ "$(boot2docker status)" != "running" ]; then
        ./boot2docker_start.sh
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
    DEVDOCKER_ID="$(docker run -d -i -p 80:80 \
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

