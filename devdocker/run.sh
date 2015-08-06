#!/bin/bash

# start apache
source /etc/apache2/envvars
exec apache2 -D FOREGROUND &

# start mysql avec initialisation de la BD si necessaire
if [ ! -d /var/lib/mysql/mysql ]; then
    mysql_install_db
fi
exec mysqld_safe

