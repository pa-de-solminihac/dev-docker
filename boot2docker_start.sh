#!/usr/bin/env bash
echo "1/3) Starting boot2docker VM"
boot2docker start

echo "2/3) Setting environment variables"
eval "$(boot2docker shellinit 2> /dev/null)"

echo "3/3) Allowing local repository if necessary"
boot2docker ssh "grep -sq \"quai2.quai13.com:5000\" /var/lib/boot2docker/profile || echo $'EXTRA_ARGS=\"--insecure-registry quai2.quai13.com:5000\"' | sudo tee -a /var/lib/boot2docker/profile && sudo /etc/init.d/docker restart"
