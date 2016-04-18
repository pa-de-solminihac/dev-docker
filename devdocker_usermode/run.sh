#!/bin/bash

# start ssh
/etc/init.d/ssh start

# start smtp server
/etc/init.d/exim4 start

# fix mysql uid so that it matches host user uid
groupmod -g $GROUP_ID devdocker # will fail if $GROUP_ID already exists, so that devdocker is the default group
usermod -u $USER_ID -g $GROUP_ID devdocker && \
    chown -R $USER_ID:$GROUP_ID /var/log/mysql && \
    chown -R $USER_ID:$GROUP_ID /var/lib/mysql

# start mysql avec initialisation de la BD si necessaire
if [ ! -d /var/lib/mysql/mysql ]; then
    echo "Initializing mysql database"
    mysql_install_db --user=devdocker
fi

# force root password and open to outside
echo "" > /mysql-force-password.sql && \
    chown devdocker:devdocker /mysql-force-password.sql && \
    chmod 400 /mysql-force-password.sql && \
    echo "USE mysql; " >> /mysql-force-password.sql && \
    echo "CREATE TEMPORARY TABLE devdocker_tmp ENGINE=MyISAM SELECT * FROM user WHERE User='root' LIMIT 1; " >> /mysql-force-password.sql && \
    echo "UPDATE devdocker_tmp SET Host='%'; " >> /mysql-force-password.sql && \
    echo "REPLACE INTO user SELECT * FROM devdocker_tmp; " >> /mysql-force-password.sql && \
    echo "DROP TABLE devdocker_tmp; " >> /mysql-force-password.sql && \
    echo "UPDATE user SET Password=PASSWORD('$MYSQL_FORCED_ROOT_PASSWORD') WHERE User='root'; " >> /mysql-force-password.sql && \
    echo "FLUSH PRIVILEGES; " >> /mysql-force-password.sql
echo "" > /root/.my.cnf && \
    chmod 400 /root/.my.cnf && \
    echo "[client]" > /root/.my.cnf && \
    echo "user=root" >> /root/.my.cnf && \
    echo "host=127.0.0.1" >> /root/.my.cnf && \
    echo "password=$MYSQL_FORCED_ROOT_PASSWORD" >> /root/.my.cnf && \
    cp -p /root/.my.cnf /home/devdocker/.my.cnf && \
    chown devdocker: /home/devdocker/.my.cnf && \
    mkdir /var/run/mysqld && \
    chown devdocker: /var/run/mysqld && \
    exec sudo -u devdocker mysqld_safe --skip-grant-tables --skip-networking --init-file=/mysql-force-password.sql &
# wait for mysql to startup in "reset password mode"
mysqld_process_pid=""
while ! [[ "$mysqld_process_pid" =~ ^[0-9]+$ ]]; do
    # limit to 60 retries (12s)
    ((c++)) && ((c==60)) && echo "Warning: giving up mysql first startup" && break
    mysqld_process_pid=$(echo "$(ps -C mysqld -o pid=)" | xargs)
    sleep 0.2
done
# then kill mysql and wait until it dies
kill $mysqld_process_pid
while ! [[ "$mysqld_process_pid" == "" ]]; do
    # limit to 60 retries (12s)
    ((c++)) && ((c==60)) && echo "Warning: giving up mysql password reset" && break
    mysqld_process_pid=$(echo "$(ps -C mysqld -o pid=)" | xargs)
    sleep 0.2
done
# and start mysql up again
exec sudo -u devdocker mysqld_safe &

# wait for mysqld_safe startup and install phpmyadmin database if necessary
if [ ! -d /var/lib/mysql/phpmyadmin ]; then
    echo "Initializing phpmyadmin database"
    while ! [[ "$mysqld_process_pid" =~ ^[0-9]+$ ]]; do
        # limit to 60 retries (12s)
        ((c++)) && ((c==60)) && echo "Warning: giving up phpmyadmin database initialization" && break
        mysqld_process_pid=$(echo "$(ps -C mysqld -o pid=)" | xargs)
        sleep 0.2
    done
    zcat /usr/share/doc/phpmyadmin/examples/create_tables.sql.gz | mysql
fi

# blackfire configuration
sed -i "s/DEVDOCKER_BLACKFIRE_CLIENT_ID/$BLACKFIRE_CLIENT_ID/g" /home/devdocker/.blackfire.ini
sed -i "s/DEVDOCKER_BLACKFIRE_CLIENT_TOKEN/$BLACKFIRE_CLIENT_TOKEN/g" /home/devdocker/.blackfire.ini
sed -i "s/DEVDOCKER_BLACKFIRE_SERVER_ID/$BLACKFIRE_SERVER_ID/g" /etc/blackfire/agent
sed -i "s/DEVDOCKER_BLACKFIRE_SERVER_TOKEN/$BLACKFIRE_SERVER_TOKEN/g" /etc/blackfire/agent
sed -i "s/^;blackfire.server_id =.*/blackfire.server_id = $BLACKFIRE_SERVER_ID/g" /etc/php5/mods-available/blackfire.ini
sed -i "s/^;blackfire.server_token =.*/blackfire.server_token = $BLACKFIRE_SERVER_TOKEN/g" /etc/php5/mods-available/blackfire.ini
sed -i "s/^;blackfire.log_file = .*/blackfire.log_file = \/tmp\/blackfire.log/g" /etc/php5/mods-available/blackfire.ini
/etc/init.d/blackfire-agent start

# start apache
source /etc/apache2/envvars
exec apache2 -D FOREGROUND

