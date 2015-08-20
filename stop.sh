#!/usr/bin/env bash

BASE_PATH="$(dirname "$0")"

# chargement du fichier de config
source $BASE_PATH/inc/base-config
if [ ! -f "$BASE_PATH/etc/config" ]; then
    cat <<EOF
    Fichier de configuration non trouvé.
EOF
    exit
else
    source $BASE_PATH/etc/config
fi

DEVDOCKER_IDS="$(docker ps | grep "\<$DEVDOCKER_IMAGE\>" | awk '{print $1}')"
if [ "$DEVDOCKER_IDS" == "" ]; then
    echo "No running devdocker containers"
else
    echo "Stopping running devdocker containers"
    docker stop "$DEVDOCKER_IDS"
fi