#!/bin/bash

# start mysql avec initialisation de la BD si necessaire
if [ ! -d /var/lib/mysql/mysql ]; then
    echo "Initializing mysql database"
    mysql_install_db
fi

exec mysqld_safe &

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

