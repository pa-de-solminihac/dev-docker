#!/usr/bin/env bash

BASE_PATH="$(dirname "$0")"
source $BASE_PATH/inc/init

if [ ! -x "$DOCKERMACHINE_PATH" ]; then
    echo
    echo -ne "\033$TERM_COLOR_RED"
    echo "# You need docker-machine!"
    echo "# Did you install Docker Toolbox?"
    echo -ne "\033$TERM_COLOR_NORMAL"
    exit
fi

if [ "$($DOCKERMACHINE status $DEVDOCKER_VM 2>&1)" == "Running" ]; then
    echo -ne "\033$TERM_COLOR_YELLOW"
    echo "# Docker VM is already running: "
    echo -ne "\033$TERM_COLOR_NORMAL"
    echo $DEVDOCKER_VM
    exit
fi

echo -ne "\033$TERM_COLOR_GREEN"
echo "# Starting Docker VM: "
echo -ne "\033$TERM_COLOR_NORMAL"
echo $DEVDOCKER_VM
if [ "$($DOCKERMACHINE ls -q | grep "^$DEVDOCKER_VM$")" == "$DEVDOCKER_VM" ]; then
    $DOCKERMACHINE start $DEVDOCKER_VM > /dev/null
else
    echo
    echo -ne "\033$TERM_COLOR_RED"
    echo "# Docker VM does not exist, maybe you should create it first, then run the restart script:"
    echo -ne "\033$TERM_COLOR_NORMAL"
    echo "$DOCKERMACHINE create -d virtualbox --virtualbox-memory 2048 --virtualbox-no-share \"$DEVDOCKER_VM\" && ./vm-restart.sh"
    echo
    exit
fi

# set environment variables
source $BASE_PATH/inc/vm-eval
eval "$DOCKER_ENV_VARS"
echo
echo -ne "\033$TERM_COLOR_YELLOW"
echo "# Run this command to configure your shell:"
echo -ne "\033$TERM_COLOR_NORMAL"
echo "eval \"\$($DOCKER_ENV_VARS_CMD)\""

# allow local repository if necessary
$DOCKERMACHINE ssh $DEVDOCKER_VM "grep -sq \"$DEVDOCKER_REPOSITORY\" /var/lib/boot2docker/profile || sudo sed -i \"s/^EXTRA_ARGS='/EXTRA_ARGS='\n--insecure-registry $DEVDOCKER_REPOSITORY/g\" /var/lib/boot2docker/profile && sudo /etc/init.d/docker restart" > /dev/null

# mount $HOME/dev through nfs
# needs this in /etc/exports: /Users/pa/dev -alldirs -mapall=pa -network 192.168.99.0 -mask 255.255.255.0
if [ -x "$(which sudo 2> /dev/null)" ]; then
    echo
    echo -ne "\033$TERM_COLOR_GREEN"
    echo "# Mounting NFS share: "
    echo -ne "\033$TERM_COLOR_NORMAL"
    echo "$HOME/dev"
    $DOCKERMACHINE ssh $DEVDOCKER_VM "sudo mount | grep -q '\.ssh.*nfs' || sudo mkdir -p $HOME/.ssh && sudo mount -t nfs -o noatime,soft,nolock,vers=3,udp,proto=udp,rsize=8192,wsize=8192,namlen=255,timeo=10,retrans=3,nfsvers=3 192.168.99.1:$HOME/.ssh $HOME/.ssh || echo 'NFS mount failed: $HOME/.ssh'"
    $DOCKERMACHINE ssh $DEVDOCKER_VM "sudo mount | grep -q '/dev.*nfs' || sudo mkdir -p $HOME/dev && sudo mount -t nfs -o noatime,soft,nolock,vers=3,udp,proto=udp,rsize=8192,wsize=8192,namlen=255,timeo=10,retrans=3,nfsvers=3 192.168.99.1:$HOME/dev $HOME/dev || echo 'NFS mount failed: $HOME/dev'"
fi

echo
echo -ne "\033$TERM_COLOR_GREEN"
echo "# Docker VM running: "
echo -ne "\033$TERM_COLOR_NORMAL"
echo $DEVDOCKER_VM
DOCKERMACHINEIP="$($DOCKERMACHINE ip $DEVDOCKER_VM)"
echo "$DOCKERMACHINEIP"

# recreate port forwarding rules
if [ -x "$(which sudo 2> /dev/null)" ]; then
    VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "tcp-port-8022" > /dev/null 2>&1 || true
    VBoxManage controlvm "$DEVDOCKER_VM" natpf1 delete "udp-port-8022" > /dev/null 2>&1 || true
    VBoxManage controlvm "$DEVDOCKER_VM" natpf1 "tcp-port-8022,tcp,,8022,,8022"
    VBoxManage controlvm "$DEVDOCKER_VM" natpf1 "udp-port-8022,udp,,8022,,8022"
fi
# other port forwarding now use sudoed SSH connection so that we don't need to sudo virtualbox

if [ "$($DOCKERMACHINE_PATH ssh $DEVDOCKER_VM 'sudo /etc/init.d/docker status')" != "Docker daemon is running" ]; then
    echo
    echo -ne "\033$TERM_COLOR_YELLOW"
    echo "# Docker daemon is not running yet, trying to start it now"
    echo -ne "\033$TERM_COLOR_NORMAL"
    # retry without --native-ssh
    $DOCKERMACHINE_PATH ssh $DEVDOCKER_VM 'sudo pkill docker' || true
    $DOCKERMACHINE_PATH ssh $DEVDOCKER_VM 'sudo /etc/init.d/docker start'
    sleep 1
    $DOCKERMACHINE_PATH ssh $DEVDOCKER_VM 'sudo /etc/init.d/docker status'
fi

