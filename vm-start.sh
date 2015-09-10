#!/usr/bin/env bash

BASE_PATH="$(dirname "$0")"
source $BASE_PATH/inc/init

if [ ! -x "$DOCKERMACHINE" ]; then
    echo
    echo -ne "\033$TERM_COLOR_RED"
    echo "You need docker-machine!"
    echo "Did you install Docker Toolbox?"
    echo -ne "\033$TERM_COLOR_NORMAL"
    exit
fi

echo -ne "\033$TERM_COLOR_GREEN"
echo -ne "Starting Docker VM: "
echo -ne "\033$TERM_COLOR_NORMAL"
echo $DEVDOCKER_VM
if [ "$($DOCKERMACHINE --native-ssh ls -q | grep "^$DEVDOCKER_VM$")" == "$DEVDOCKER_VM" ]; then
    $DOCKERMACHINE --native-ssh start $DEVDOCKER_VM > /dev/null
else
    echo
    echo -ne "\033$TERM_COLOR_RED"
    echo "Docker VM does not exist, maybe you should create it first:"
    echo -ne "\033$TERM_COLOR_NORMAL"
    echo "$DOCKERMACHINE --native-ssh create -d virtualbox --virtualbox-memory 2048 --virtualbox-no-share \"$DEVDOCKER_VM\""
    exit
fi

# set environment variables
DOCKER_ENV_VARS_CMD="$DOCKERMACHINE --native-ssh env $DEVDOCKER_VM"
DOCKER_ENV_VARS="$($DOCKER_ENV_VARS_CMD)"
eval "$DOCKER_ENV_VARS"
echo
echo "# Run this command to configure your shell:"
echo "eval \"\$($DOCKER_ENV_VARS_CMD)\""

# allow local repository if necessary
$DOCKERMACHINE --native-ssh ssh $DEVDOCKER_VM "grep -sq \"$DEVDOCKER_REPOSITORY\" /var/lib/boot2docker/profile || sudo sed -i \"s/^EXTRA_ARGS='/EXTRA_ARGS='\n--insecure-registry $DEVDOCKER_REPOSITORY/g\" /var/lib/boot2docker/profile && sudo /etc/init.d/docker restart" > /dev/null

# mount $HOME/dev through nfs
# needs this in /etc/exports: /Users/pa/dev -alldirs -mapall=pa -network 192.168.99.0 -mask 255.255.255.0
echo
echo -ne "\033$TERM_COLOR_GREEN"
echo -ne "Mounting NFS share: "
echo -ne "\033$TERM_COLOR_NORMAL"
echo "$HOME/dev"
$DOCKERMACHINE --native-ssh ssh $DEVDOCKER_VM "sudo mount | grep -q nfs || sudo mkdir -p $HOME/dev && sudo mount -t nfs -o noatime,soft,nolock,vers=3,udp,proto=udp,rsize=8192,wsize=8192,namlen=255,timeo=10,retrans=30,nfsvers=3 192.168.99.1:$HOME/dev $HOME/dev || echo 'NFS mount failed'"

echo
echo -ne "\033$TERM_COLOR_GREEN"
echo -ne "Docker VM running: "
echo -ne "\033$TERM_COLOR_NORMAL"
echo $DEVDOCKER_VM
$DOCKERMACHINE --native-ssh ip $DEVDOCKER_VM

# recreate port forwarding rules
VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "tcp-port-8022" > /dev/null 2>&1
VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "udp-port-8022" > /dev/null 2>&1
VBoxManage controlvm "$DEVDOCKER_VM" natpf1 "tcp-port-8022,tcp,,8022,,8022"
VBoxManage controlvm "$DEVDOCKER_VM" natpf1 "udp-port-8022,udp,,8022,,8022"
# other port forwarding now use sudoed SSH connection so that we don't need to sudo virtualbox
