#!/bin/bash
# run in background, attaching a shell

# usage
function usage() {
    cat <<EOF

    Usage
    =====

    DOCKERSITE_ROOT="/c/Users/...../path/to/dockersite" SSH_DIR="/c/Users/...../path/to/.ssh" ./run.sh
EOF
}

# check parameters
if [ "$DOCKERSITE_ROOT" == "" ] || [ ! -d "$DOCKERSITE_ROOT" ]; then
    echo "Error: missing DOCKERSITE_ROOT value or not pointing to a directory $DOCKERSITE_ROOT"
    echo
    usage
    exit
fi

if [ "$SSH_DIR" == "" ]; then
    SSH_DIR="$HOME/.ssh"
fi

if [ ! -d "$SSH_DIR" ]; then
    echo "Error: missing SSH_DIR value or not pointing to a directory $SSH_DIR"
    echo
    usage
    exit
fi

# attach to running container if possible, or spawn a new one
DEVDOCKER_ID="$(docker ps | grep devdocker | head -n 1 | awk '{print $1}')"
echo "$DEVDOCKER_ID" 
if [ "$DEVDOCKER_ID" == "" ]; then
    DEVDOCKER_ID="$(docker run -d -i -p 80:80 \
        -v "$SSH_DIR:/root/.ssh-readonly:ro" \
        -v "$DOCKERSITE_ROOT/www:/var/www/html" \
        -v "$DOCKERSITE_ROOT/database:/var/lib/mysql" \
        -v "$DOCKERSITE_ROOT/vhosts:/etc/apache2/vhosts" \
        -v "$DOCKERSITE_ROOT/log:/var/log/dockersite" \
        -v "$DOCKERSITE_ROOT/conf-sitesync:/sitesync/etc" \
        devdocker)"
    echo "Attaching to freshly started container $DEVDOCKER_ID"
else
    echo "Attaching to already running container $DEVDOCKER_ID"
fi
docker exec -i -t "$DEVDOCKER_ID" bash

