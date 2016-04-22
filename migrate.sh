#!/usr/bin/env bash

# sur le serveur source
#mysqldump --add-drop-database --database $(echo "show databases" | mysql | grep -Ev "^(Database|mysql|performance_schema|information_schema|phpmyadmin)$") > dockersite/database/all.sql

# dans la machine docker
#cd /var/lib/mysql && mysql --show-warnings < all.sql > all.sql.log
