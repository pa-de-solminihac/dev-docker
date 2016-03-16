#!/usr/bin/env bash
cp -f /home/mysql/.ssh-readonly/* /home/mysql/.ssh/ 2>/dev/null
chown -R mysql: /home/mysql/.ssh
