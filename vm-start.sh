#!/usr/bin/env bash

BASE_PATH="$(dirname "$0")"
source $BASE_PATH/inc/init

if [ ! -x "$DOCKERMACHINE" ]; then
    echo
    echo "You need docker-machine!"
    echo "Did you install Docker Toolbox?"
    exit
fi

echo "Starting docker VM \"$DEVDOCKER_VM\""
if [ "$($DOCKERMACHINE --native-ssh ls -q | grep "^$DEVDOCKER_VM$")" == "$DEVDOCKER_VM" ]; then
    $DOCKERMACHINE --native-ssh start $DEVDOCKER_VM > /dev/null
else
    echo
    echo "VM does not exist, maybe you should create it first: "
    echo "$DOCKERMACHINE --native-ssh create -d virtualbox \"$DEVDOCKER_VM\""
    exit
fi

# setting environment variables
DOCKER_ENV_VARS="$($DOCKERMACHINE --native-ssh env $DEVDOCKER_VM)"
eval "$DOCKER_ENV_VARS"
echo "$DOCKER_ENV_VARS"

# allowing local repository if necessary
$DOCKERMACHINE --native-ssh ssh $DEVDOCKER_VM "grep -sq \"quai2.quai13.com:5000\" /var/lib/boot2docker/profile || sudo sed -i \"s/^EXTRA_ARGS='/EXTRA_ARGS='\n--insecure-registry quai2.quai13.com:5000/g\" /var/lib/boot2docker/profile && sudo /etc/init.d/docker restart" > /dev/null

echo
echo "Your VM is up and running with IP:"
$DOCKERMACHINE --native-ssh ip $DEVDOCKER_VM
