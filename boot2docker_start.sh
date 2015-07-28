#!/usr/bin/env bash
boot2docker start
$( boot2docker shellinit 2> /dev/null )
boot2docker ip
