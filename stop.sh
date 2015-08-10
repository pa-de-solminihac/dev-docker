#!/usr/bin/env bash
docker stop $(docker ps | grep '\<devdocker\>' | awk '{print $1}')
