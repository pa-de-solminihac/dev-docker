FROM debian:jessie
MAINTAINER Pierre-Alexis de Solminihac <pa@quai13.com>

# Set the locale
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apt-utils
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install dialog
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install locales-all
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install net-tools
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apache2 libapache2-mod-php5 php5-apcu
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install memcached php5-memcache php5-memcached
#RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php-opcache
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-intl php-gettext
#RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php-iconv
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-mysqlnd php5-pgsql
#RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php-pdo php-pdo_mysql php-pdo_pgsql php5-mysql
#RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php-openssl
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-json php5-xsl
#RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php-xml
#RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php-zlib
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-imap php5-curl php5-gd
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install bash bash-completion
#RUN DEBIAN_FRONTEND=noninteractive apt-get -y install docker-bash-completion git-bash-completion
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install ncdu vim ncurses-bin
#RUN DEBIAN_FRONTEND=noninteractive apt-get -y install vimdiff
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install grep ack-grep
#RUN DEBIAN_FRONTEND=noninteractive apt-get -y install perl
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install git
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mariadb-client
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install openssh-client rsync
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install lynx curl wget
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install phpmyadmin
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install manpages

# dossier pour les logs
RUN mkdir -p /var/log/dockersite
RUN chmod 777 /var/log/dockersite

# config apache
RUN a2enmod rewrite
RUN a2enmod headers
RUN a2enmod expires
RUN a2enmod ssl
RUN mkdir -p /etc/apache2/dockersite-vhosts
RUN echo "IncludeOptional dockersite-vhosts/*.conf" >> /etc/apache2/apache2.conf
RUN echo "Servername localhost" >> /etc/apache2/apache2.conf
RUN sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf
RUN sed -i "s/export APACHE_LOG_DIR=.*/export APACHE_LOG_DIR=\/var\/log\/dockersite$SUFFIX/g" /etc/apache2/envvars
ADD 000-default.conf /etc/apache2/sites-enabled/

# config php
RUN sed -i "s/^display_errors = Off/display_errors = On/g" /etc/php5/apache2/php.ini
RUN sed -i "s/^track_errors = Off/track_errors = On/g" /etc/php5/apache2/php.ini
RUN sed -i "s/^;error_log = php_errors.log/error_log = \/var\/log\/dockersite\/php_errors.log/g" /etc/php5/apache2/php.ini
RUN sed -i "s/^disable_functions =.*/disable_functions = shell-exec, system, passthru, popen/g" /etc/php5/apache2/php.ini
RUN sed -i "s/^; max_input_vars =.*/max_input_vars = 2000/g" /etc/php5/apache2/php.ini
RUN sed -i "s/^post_max_size =.*/post_max_size = 32M/g" /etc/php5/apache2/php.ini
RUN sed -i "s/^upload_max_filesize =.*/upload_max_filesize = 32M/g" /etc/php5/apache2/php.ini
RUN sed -i "s/^;date\.timezone =.*/date.timezone = 'Europe\/Paris'/g" /etc/php5/apache2/php.ini

# config phpmyadmin
RUN echo "Include /etc/phpmyadmin/apache.conf" >> /etc/apache2/apache2.conf
RUN sed -i 's/.*\($cfg..Servers...$i...AllowNoPassword.. *= *\).*/\1TRUE;/g' /etc/phpmyadmin/config.inc.php

# Workaround for write permission on write to MacOS X volumes
# See https://github.com/boot2docker/boot2docker/pull/534
RUN adduser --no-create-home --disabled-login --gecos "" mysql --uid 1000
RUN usermod -G staff mysql

# install mysql (mariadb)
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mariadb-server

# config mysql
RUN sed -i "s/^query_cache_limit.*/slow_query_log = 1\nslow_query_log_file = \/var\/log\/dockersite\/mysql-slow.log\nlong_query_time = 2/g" /etc/mysql/my.cnf
RUN sed -i "s/^query_cache_size.*/query_cache_type = 1\nquery_cache_limit = 16M\nquery_cache_size = 256M\nopen_files_limit = 9999\ninnodb_buffer_pool_size = 32M\nmax_allowed_packet = 32M\ninnodb_log_file_size = 32M\n/g" /etc/mysql/my.cnf
RUN sed -i "s/#character-set-server/character-set-server/g" /etc/mysql/conf.d/mariadb.cnf
RUN sed -i "s/#character_set_server/character_set_server/g" /etc/mysql/conf.d/mariadb.cnf
RUN sed -i "s/#collation-server/collation-server/g" /etc/mysql/conf.d/mariadb.cnf
RUN sed -i "s/#collation_server/collation_server/g" /etc/mysql/conf.d/mariadb.cnf
RUN sed -i "s/#default-character-set/default-character-set/g" /etc/mysql/conf.d/mariadb.cnf

# hack perms because of boo2docker's limitations
RUN sed -i "s/export APACHE_RUN_USER=www-data/export APACHE_RUN_USER=mysql/g" /etc/apache2/envvars
RUN sed -i "s/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=mysql/g" /etc/apache2/envvars
RUN chgrp mysql /var/lib/phpmyadmin/* /etc/phpmyadmin/config-db.php /etc/phpmyadmin/htpasswd.setup

# copy your readonly mounted ssh keys and config
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh && echo "cp -f /root/.ssh-readonly/* /root/.ssh/ 2>/dev/null" >> ~/.bashrc

# install sitesync
RUN git clone https://github.com/pa-de-solminihac/sitesync.git /sitesync && \
    echo 'export PATH="$PATH:/sitesync"' >> ~/.bashrc

# outils de base pour configuration minimale
RUN cd /root/ && \
    git clone https://github.com/pa-de-solminihac/configuration.git && \
    echo "source ~/.bashrc_local" >> ~/.bashrc && \
    ln -s ~/configuration/bash/.bashrc_local && \
    ln -s ~/configuration/bash/.bashrc_common && \
    echo "source ~/.vimrc_common" >> ~/.vimrc && \
    ln -s ~/configuration/vim/.vimrc_common && \
    mkdir -p bin && \
    ln -s ~/configuration/bin/diffconflicts bin/

# cd dans /var/www/html au login
RUN echo 'cd /var/www/html' >> ~/.bashrc

# install drush
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install drush

# install wp-wned.sh
ADD wp-wned.sh /usr/local/bin/

# install wp-cli
RUN cd /usr/local/bin && curl -O "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" && chmod +x wp-cli.phar && mv wp-cli.phar wp

# cleanup
RUN DEBIAN_FRONTEND=noninteractive apt-get -y clean

# expose port 80
EXPOSE 80

# run : attention, CMD fonctionne avec le caractère " mais pas avec le caractère ' !!!
ADD run.sh /run.sh
RUN chmod 755 /run.sh
CMD ["/run.sh"]
