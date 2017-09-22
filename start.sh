#!/usr/bin/env bash

QUIET="$#"

BASE_PATH="$(dirname "$0")"
source $BASE_PATH/inc/init

# run docker-machine VM if necessary
if [ -x "$DOCKERMACHINE_PATH" ]; then
    # ask for root password as early as possible, and only once, to improve UX
    if [ -x "$(which sudo 2> /dev/null)" ]; then
        sudo echo -n || exit
    fi
    # checking if docker VM is running ($DEVDOCKER_VM)
    if [ "$("$DOCKERMACHINE" status $DEVDOCKER_VM 2>&1)" != "Running" ]; then
        . ./vm-start.sh
        echo
    fi
    # setting environment variables
    source $BASE_PATH/inc/vm-eval
    eval "$DOCKER_ENV_VARS"
fi

# cleanup exited devdocker containers
docker rm -v $(docker ps --filter status=exited --filter image=$DEVDOCKER_IMAGE -q 2>/dev/null) 2>/dev/null > /dev/null || true
docker rmi $(docker images --filter dangling=true -q 2>/dev/null) 2>/dev/null > /dev/null || true

# attach to running container if possible, or spawn a new one
DEVDOCKER_ID="$(docker ps | (grep "\<$DEVDOCKER_IMAGE\>" || true) | head -n 1 | awk '{print $1}')"
if [ "$DEVDOCKER_ID" == "" ]; then
    # run "git pull" if updates are available, so that scripts are always on par with docker images
    # get latest image from local repository
    if [ "$DEVDOCKER_AUTOUPDATE" == "1" ]; then
        GIT_CURRENT_BRANCH="$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)"
        if [ "$(git fetch --all | grep -v 'Fetching origin'; git log --oneline ..origin/$GIT_CURRENT_BRANCH | wc -l | xargs)" != "0" ] && [ "$DEVDOCKER_DONT_GITPULL" != "1" ]; then
            if [ "$(git status --short . | grep -v '^??' | wc -l)" != "0" ]; then
                echo -ne "\033$TERM_COLOR_YELLOW";
                echo
                echo "# Warning: updates available, but git status is not clean. Skipping git autoupdate."
                echo
                echo -ne "\033$TERM_COLOR_NORMAL"
                git status --short .
                echo -ne "\033$TERM_COLOR_YELLOW";
                echo
                echo "# Skipping git autoupdate."
                echo -ne "\033$TERM_COLOR_NORMAL"
            else
                git pull
                DEVDOCKER_DONT_GITPULL="1" ./start.sh
                exit
            fi
        fi
        docker pull "$DEVDOCKER_IMAGE" | grep -v ': Already exists$' || (echo -ne "\033$TERM_COLOR_YELLOW" && echo && echo "# Warning: autoupdate failed" && echo && echo -ne "\033$TERM_COLOR_NORMAL")
    fi
    # force required directories to exist
    mkdir -p "$DOCKERSITE_ROOT"/www
    mkdir -p "$DOCKERSITE_ROOT"/database/binlog
    chmod 755 "$DOCKERSITE_ROOT"/database/* 2> /dev/null || true # fix database permissions at startup
    mkdir -p "$DOCKERSITE_ROOT"/apache2
    mkdir -p "$DOCKERSITE_ROOT"/log
    mkdir -p "$DOCKERSITE_ROOT"/crontabs
    mkdir -p "$DOCKERSITE_ROOT"/bashrc.d
    mkdir -p "$DOCKERSITE_ROOT"/conf-sitesync
    # run container
    DEVDOCKER_ID="$(docker run -h $DEVDOCKER_HOSTNAME --rm --privileged -d -i \
        -p 8022:8022 \
        -p 80:80 \
        -p 443:443 \
        -p 3306:3306 \
        -p 9200:9200 \
        -p 9300:9300 \
        -p 6081:6081 \
        -p 6082:6082 \
        -p 5601:5601 \
        -e "USER_ID=$(id -u)" \
        -e "GROUP_ID=$(id -g)" \
        -e "USER_FULLNAME=\"$USER_FULLNAME\"" \
        -e "MYSQL_FORCED_ROOT_PASSWORD=$MYSQL_FORCED_ROOT_PASSWORD" \
        -e "BLACKFIRE_SERVER_ID=$BLACKFIRE_SERVER_ID" \
        -e "BLACKFIRE_SERVER_TOKEN=$BLACKFIRE_SERVER_TOKEN" \
        -e "BLACKFIRE_CLIENT_ID=$BLACKFIRE_CLIENT_ID" \
        -e "BLACKFIRE_CLIENT_TOKEN=$BLACKFIRE_CLIENT_TOKEN" \
        -e "START_DOCKER_IN_DOCKER=$START_DOCKER_IN_DOCKER" \
        -e "START_MEMCACHED=$START_MEMCACHED" \
        -e "START_VARNISH=$START_VARNISH" \
        -e "START_REDIS=$START_REDIS" \
        -e "START_ELK=$START_ELK" \
        -v "$SSH_DIR:/home/devdocker/.ssh-readonly:ro" \
        -v "$DOCKERSITE_ROOT/www:/var/www/html" \
        -v "$DOCKERSITE_ROOT/database:/var/lib/mysql" \
        -v "$DOCKERSITE_ROOT/apache2:/etc/apache2/dockersite" \
        -v "$DOCKERSITE_ROOT/log:/var/log/dockersite" \
        -v "$DOCKERSITE_ROOT/crontabs:/var/spool/cron/crontabs" \
        -v "$DOCKERSITE_ROOT/bashrc.d:/home/devdocker/bashrc.d" \
        -v "$DOCKERSITE_ROOT/conf-sitesync:/sitesync/etc" \
        "$DEVDOCKER_IMAGE")"
    if [[ "$QUIET" == "0" ]]; then
        echo -ne "\033$TERM_COLOR_GREEN"
        echo "# Attaching to freshly started container: "
        echo -ne "\033$TERM_COLOR_NORMAL"
        echo $DEVDOCKER_ID
    fi
    # save container hosts file before we complete it with every login
    docker exec "$DEVDOCKER_ID" sh -c "cp /etc/hosts /etc/hosts.ori"
    # wait enough time for usermod to finish cleanly in run.sh
    if [[ "$QUIET" == "0" ]]; then
        echo
        echo -ne "\033$TERM_COLOR_YELLOW"
        echo "# Mapping permissions:"
        echo -n "    devdocker";
        sleep 1;
        echo -n " = "
        sleep 1;
        echo "$(id -n -u)"
        sleep 1;
        echo -n "    users"
        sleep 1;
        echo -n " = "
        sleep 1;
        echo -n "$(id -n -g)"
        echo -e "\033$TERM_COLOR_NORMAL"
    fi
else
    # fix database permissions at startup
    chmod 755 "$DOCKERSITE_ROOT"/database/* 2> /dev/null || true # fix database permissions at startup
    if [[ "$QUIET" == "0" ]]; then
        echo -ne "\033$TERM_COLOR_YELLOW"
        echo "# Attaching to already running container: "
        echo -ne "\033$TERM_COLOR_NORMAL"
        echo $DEVDOCKER_ID
    fi
fi

# copy /etc/hosts at every startup
ETC_HOSTS="$(cat /etc/hosts)"
docker exec "$DEVDOCKER_ID" sh -c "cat /etc/hosts.ori > /etc/hosts && echo \"$ETC_HOSTS\" >> /etc/hosts"

# use SSH to attach to container and forward reserved ports
if [[ "$QUIET" == "0" ]]; then
    echo
fi
docker exec "$DEVDOCKER_ID" /copy-ssh-config.sh || true
# fix for weird write permission bug on /hom/devdocker/.ssh directory
docker exec "$DEVDOCKER_ID" sh -c "mv ~/.ssh ~/.ssh2 && mv ~/.ssh2 ~/.ssh"
docker exec --user devdocker "$DEVDOCKER_ID" sh -c "mv ~/.ssh ~/.ssh2 && mv ~/.ssh2 ~/.ssh"
# allow user's own public key
PUBKEY_START="$(cat $SSH_PUBKEY | awk '{print $1}')"
PUBKEY_MID="$(cat $SSH_PUBKEY | awk '{print $2}')"
docker exec "$DEVDOCKER_ID" sh -c "grep -sq \"$PUBKEY_MID\" /root/.ssh/authorized_keys || echo \"$PUBKEY_START $PUBKEY_MID devdocker_owner\" >> /root/.ssh/authorized_keys"
docker exec --user devdocker "$DEVDOCKER_ID" sh -c "grep -sq \"$PUBKEY_MID\" /home/devdocker/.ssh/authorized_keys || echo \"$PUBKEY_START $PUBKEY_MID devdocker_owner\" >> /home/devdocker/.ssh/authorized_keys"

# TODO: identifier les commits faits depuis l'intérieur de la vm
#PUBKEY_END="$(cat $SSH_PUBKEY | awk '{print $3}')"
#docker exec "$DEVDOCKER_ID" sh -c "echo \"$PUBKEY_END\" >> /home/devdocker/.gitconfig"
# forwarding ports only if VM is in use and ports are not already forwarded
if [ -x "$DOCKERMACHINE_PATH" ]; then
    # no quotes around echo $SSH_PORT_FW_CMD to suppress additionnal spaces, or grep wont grep
    PORT_FW_PID="$(ps auwx | (grep "$(echo $SSH_PORT_FW_CMD)" | grep -v 'grep' | grep -v 'sudo' || true) | awk '{print $2}')";
    if [ "$PORT_FW_PID" == "" ]; then
        if [[ "$QUIET" == "0" ]]; then
            echo -ne "\033$TERM_COLOR_GREEN"
            echo "# Forwarding ports using SSH"
            echo -ne "\033$TERM_COLOR_NORMAL"
        fi
        if [ -x "$(which sudo 2> /dev/null)" ]; then
            sudo echo -n || exit # ask for root password again if sudo timed out
            # OSX specific: bind 127.0.0.2 to loopback, cf. https://superuser.com/a/458877/496146
            SILENCE="$(sudo ifconfig lo0 alias 127.0.0.2 up)" &
            SILENCE="$(sudo $SSH_PORT_FW_CMD 2>&1 > /dev/null)" &
        else
            SILENCE="$($SSH_PORT_FW_CMD 2>&1 > /dev/null)" &
        fi

    else
        if [[ "$QUIET" == "0" ]]; then
            echo -ne "\033$TERM_COLOR_YELLOW"
            echo "# Ports are already forwarded using SSH"
            #echo "# Ports are already forwarded using SSH: $SSH_PORT_FW_CMD"
            echo -ne "\033$TERM_COLOR_NORMAL"
        fi
    fi
fi
$SSH_CMD "$@" || true
