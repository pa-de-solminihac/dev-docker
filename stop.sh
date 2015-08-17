#!/usr/bin/env bash

BASE_PATH="$(dirname "$0")"

# chargement du fichier de config
if [ ! -f "$BASE_PATH/etc/config" ]; then
    cat <<EOF
    Fichier de configuration non trouvé.
EOF
    exit
else
    source $BASE_PATH/etc/config
fi

docker stop $(docker ps | grep "\<$DEVDOCKER_IMAGE\>" | awk '{print $1}')
