#!/usr/bin/env bash
cp -f /home/devdocker/.ssh-readonly/* /root/.ssh/ 2>/dev/null
cp -f /home/devdocker/.ssh-readonly/* /home/devdocker/.ssh/ 2>/dev/null
chown -R root: /root/.ssh
chown -R devdocker: /home/devdocker/.ssh
