#!/usr/bin/env bash
boot2docker start
eval "$(boot2docker shellinit 2> /dev/null)"
# allow quai2.quai13.com if not already allowed
boot2docker ssh "grep -sq \"quai2.quai13.com:5000\" /var/lib/boot2docker/profile || echo $'EXTRA_ARGS=\"--insecure-registry quai2.quai13.com:5000\"' | sudo tee -a /var/lib/boot2docker/profile && sudo /etc/init.d/docker restart"
boot2docker ip
