#!/usr/bin/env bash
docker stop $(docker ps | grep '\<quai2.quai13.com:5000/devdocker\>' | awk '{print $1}')
