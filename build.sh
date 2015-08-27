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

docker build $@ -f devdocker/Dockerfile -t $DEVDOCKER_IMAGE:latest devdocker
cat <<EOL
Now you can tag and push the image:
    docker push $DEVDOCKER_IMAGE
EOL

