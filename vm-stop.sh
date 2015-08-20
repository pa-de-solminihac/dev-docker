#!/usr/bin/env bash
echo "Stopping docker VM"
DOCKERMACHINE="$(which docker-machine 2>/dev/null)"
$DOCKERMACHINE --native-ssh stop $DEVDOCKER_VM
