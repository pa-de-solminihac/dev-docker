#!/bin/bash

# start mysql avec initialisation de la BD si necessaire
if [ ! -d /var/lib/mysql/mysql ]; then
    echo "Initializing mysql database"
    mysql_install_db
fi

# force root password and open to outside
echo "" > /mysql-force-password.sql && \
    chown mysql:mysql /mysql-force-password.sql && \
    chmod 400 /mysql-force-password.sql && \
    echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION; " >> /mysql-force-password.sql && \
    echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION; " >> /mysql-force-password.sql && \
    echo "FLUSH PRIVILEGES; " >> /mysql-force-password.sql
echo "" > /root/.my.cnf && \
    chmod 400 /root/.my.cnf && \
    echo "[client]" > /root/.my.cnf && \
    echo "password=$MYSQL_ROOT_PASSWORD" >> /root/.my.cnf && \

exec mysqld_safe --init-file=/mysql-force-password.sql &

# wait for mysqld_safe startup and install phpmyadmin database if necessary
if [ ! -d /var/lib/mysql/phpmyadmin ]; then
    echo "Initializing phpmyadmin database"
    while ! [[ "$mysqld_process_pid" =~ ^[0-9]+$ ]]; do
        # limit to 30 retries (6s)
        ((c++)) && ((c==30)) && echo "Warning: giving up phpmyadmin database initialization" && break
        mysqld_process_pid=$(echo "$(ps -C mysqld -o pid=)" | xargs)
        sleep 0.2
    done
    zcat /usr/share/doc/phpmyadmin/examples/create_tables.sql.gz | mysql
fi

# start apache
source /etc/apache2/envvars
exec apache2 -D FOREGROUND

