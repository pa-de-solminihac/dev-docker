#!/usr/bin/env bash

BASE_PATH="$(dirname "$0")"
source $BASE_PATH/inc/init

if [ ! -x "$DOCKERMACHINE" ]; then
    echo
    echo "You need docker-machine!"
    echo "Did you install Docker Toolbox?"
    exit
fi

echo "Starting Docker VM: $DEVDOCKER_VM"
if [ "$($DOCKERMACHINE --native-ssh ls -q | grep "^$DEVDOCKER_VM$")" == "$DEVDOCKER_VM" ]; then
    $DOCKERMACHINE --native-ssh start $DEVDOCKER_VM > /dev/null
else
    echo
    echo "Docker VM does not exist, maybe you should create it first:"
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
echo "Docker VM running: $DEVDOCKER_VM"
$DOCKERMACHINE --native-ssh ip $DEVDOCKER_VM

# recreate port forwarding rules
VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "tcp-port-80" > /dev/null 2>&1
VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "udp-port-80" > /dev/null 2>&1
VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "tcp-port-443" > /dev/null 2>&1
VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "udp-port-443" > /dev/null 2>&1
VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "tcp-port-3306" > /dev/null 2>&1
VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "udp-port-3306" > /dev/null 2>&1
VBoxManage controlvm "$DEVDOCKER_VM" natpf1 "tcp-port-80,tcp,,80,,80"
VBoxManage controlvm "$DEVDOCKER_VM" natpf1 "udp-port-80,udp,,80,,80"
VBoxManage controlvm "$DEVDOCKER_VM" natpf1 "tcp-port-443,tcp,,443,,443"
VBoxManage controlvm "$DEVDOCKER_VM" natpf1 "udp-port-443,udp,,443,,443"
VBoxManage controlvm "$DEVDOCKER_VM" natpf1 "tcp-port-3306,tcp,,3306,,3306"
VBoxManage controlvm "$DEVDOCKER_VM" natpf1 "udp-port-3306,udp,,3306,,3306"

