#!/bin/bash
# run en background et attache un bash

if [ "$DOCKERSITE_ROOT" == "" ] || [ ! -d "$DOCKERSITE_ROOT" ]; then
    echo "Error: missing DOCKERSITE_ROOT value or not pointing to a directory $DOCKERSITE_ROOT"
    echo
    echo 'Usage: DOCKERSITE_ROOT="/c/Users/...../path/to/dockersite" ./run.sh'
    exit
fi

DEVDOCKER_ID="$(docker ps | grep dockersite | head -n 1 | awk '{print $1}')"
if [ "$DEVDOCKER_ID" == "" ]; then
    DEVDOCKER_ID="$(docker run -d -i -p 80:80 -v "$DOCKERSITE_ROOT/www:/var/www/html" -v "$DOCKERSITE_ROOT/dockersite/database:/var/lib/mysql" -v "$DOCKERSITE_ROOT/dockersite/vhosts:/etc/apache2/vhosts" -v "$DOCKERSITE_ROOT/dockersite/log:/var/log/dockersite" dockersite)"
    echo "Attaching to freshly started container $DEVDOCKER_ID"
else
    echo "Attaching to already running container $DEVDOCKER_ID"
fi
docker exec -i -t "$DEVDOCKER_ID" bash

# Attention sous windows : il faut des chemins sous C:\Users forcement, et specifies sous la forme "/c/Users/...../dockersite/www:/var/www/html"

