#!/usr/bin/env bash

BASE_PATH="$(dirname "$0")"
source $BASE_PATH/inc/init

# run docker-machine VM if necessary
if [ -x "$DOCKERMACHINE" ]; then
    # checking if docker VM is running ($DEVDOCKER_VM)
    if [ "$($DOCKERMACHINE --native-ssh status $DEVDOCKER_VM)" != "Running" ]; then
        . ./vm-start.sh
    fi
    # set environment variables
    source $BASE_PATH/inc/vm-eval
    eval "$DOCKER_ENV_VARS"
fi

BUILD_OK=0
docker build $@ -f devdocker/Dockerfile -t $DEVDOCKER_IMAGE:latest devdocker && BUILD_OK=1
if [ "$BUILD_OK" == "1" ]; then

    if [ -x "$DOCKERMACHINE" ]; then
        echo
        echo "# Run this command to configure your shell:"
        echo "eval \"\$($DOCKER_ENV_VARS_CMD)\""
        echo
    fi

    cat <<EOL
Now you can tag and push the image:
    docker push $DEVDOCKER_IMAGE
EOL

fi
