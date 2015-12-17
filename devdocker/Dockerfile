FROM debian:jessie
MAINTAINER Pierre-Alexis de Solminihac <pa@quai13.com>

#####################
# ENABLE REPOSITORIES
#####################

# enable blackfire.io additional repository
ADD https://packagecloud.io/gpg.key /tmp/blackfire.key
RUN DEBIAN_FRONTEND=noninteractive apt-key add /tmp/blackfire.key && \
    echo "deb http://packages.blackfire.io/debian any main" | tee /etc/apt/sources.list.d/blackfire.list

# enable debian jessie backports
RUN echo "deb http://httpredir.debian.org/debian jessie-backports main" | tee /etc/apt/sources.list.d/backports.list


#################################
# WORKAROUND for write permission
#################################

# See https://github.com/boot2docker/boot2docker/pull/534
ENV USER_ID=1000
RUN adduser --no-create-home --disabled-login --gecos "" mysql --uid $USER_ID && \
    usermod -G staff mysql


##################
# INSTALL PACKAGES
##################

# install required packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apt-utils
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install dialog
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install locales-all
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install net-tools dnsutils
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apache2 libapache2-mod-php5 php5-apcu
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install memcached php5-memcache php5-memcached
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-intl php-gettext
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-mysqlnd php5-pgsql
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-json php5-xsl
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-imap php5-curl php5-gd
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install bash bash-completion
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install ncdu vim ncurses-bin
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install grep ack-grep
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install git
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mariadb-client
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install openssh-server openssh-client rsync
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install lynx curl wget
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install phpmyadmin
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install man-db manpages
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install blackfire-agent blackfire-php
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mariadb-server
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mailutils
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install drush
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install build-essential autoconf pkg-config nasm libtool

# install libreoffice from backports
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install openjdk-7-jre
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install -t jessie-backports libreoffice-writer


##########################
# INSTALL WITHOUT PACKAGES
##########################

# install sitesync
RUN git clone https://github.com/pa-de-solminihac/sitesync.git /sitesync
COPY profile.d_sitesync.sh /etc/profile.d/sitesync.sh

# better shell config
WORKDIR /root/
RUN git clone https://github.com/pa-de-solminihac/configuration.git && \
    echo "source /root/.bashrc_local" >> /root/.bashrc && \
    ln -s /root/configuration/bash/.bashrc_local && \
    ln -s /root/configuration/bash/.bashrc_common && \
    echo "source /root/.vimrc_common" >> /root/.vimrc && \
    ln -s /root/configuration/vim/.vimrc_common && \
    mkdir -p bin && \
    ln -s /root/configuration/bin/diffconflicts bin/

# mozjpeg and jpeg-archive
WORKDIR /usr/local/src/
RUN git clone https://github.com/mozilla/mozjpeg.git && \
    cd mozjpeg && \
    autoreconf -fiv && \
    ./configure --with-jpeg8 && \
    make && \
    make install
RUN git clone https://github.com/danielgtaylor/jpeg-archive.git && \
    cd jpeg-archive && \
    make && \
    make install

# install wp-wned.sh
COPY wp-wned.sh /usr/local/bin/

# install wp-cli
WORKDIR /usr/local/bin
RUN curl -O "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar wp && \
    echo "alias wp='wp --allow-root '" >> /root/.bashrc


###########
# CONFIGURE
###########

# timezone
ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# logs directory
RUN mkdir -p /var/log/dockersite && \
    chmod 777 /var/log/dockersite

# configure git
COPY gitconfig /root/.gitconfig

# configure blackfire
COPY blackfire-agent /etc/blackfire/agent
COPY blackfire-client /root/.blackfire.ini

# apache
COPY 000-default.conf /etc/apache2/sites-enabled/
RUN a2enmod rewrite && \
    a2enmod headers && \
    a2enmod expires && \
    a2enmod include && \
    a2enmod ssl && \
    echo 'Servername localhost' >> /etc/apache2/apache2.conf && \
    sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf && \
    sed -i 's/export APACHE_LOG_DIR=.*/export APACHE_LOG_DIR=\/var\/log\/dockersite$SUFFIX/g' /etc/apache2/envvars && \
    sed -i 's/Listen 80/Listen 0.0.0.0:80/g' /etc/apache2/ports.conf && \
    sed -i 's/Listen 443/Listen 0.0.0.0:443/g' /etc/apache2/ports.conf && \
    sed -i 's/CustomLog ${APACHE_LOG_DIR}\/access.log combined/CustomLog ${APACHE_LOG_DIR}\/access.log dockersite/g' /etc/apache2/sites-available/000-default.conf && \
    sed -i 's/CustomLog ${APACHE_LOG_DIR}\/access.log combined/CustomLog ${APACHE_LOG_DIR}\/access.log dockersite/g' /etc/apache2/sites-available/default-ssl.conf && \
    mkdir -p /etc/apache2/dockersite && \
    echo 'LogFormat "%V:%p %h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" dockersite' >> /etc/apache2/apache2.conf && \
    echo 'IncludeOptional dockersite/*.conf' >> /etc/apache2/apache2.conf

# apache: workaround for write permission
RUN sed -i "s/export APACHE_RUN_USER=www-data/export APACHE_RUN_USER=mysql/g" /etc/apache2/envvars && \
    sed -i "s/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=mysql/g" /etc/apache2/envvars && \
    chgrp mysql /var/lib/phpmyadmin/* /etc/phpmyadmin/config-db.php /etc/phpmyadmin/htpasswd.setup

# php
RUN sed -i "s/^display_errors = Off/display_errors = On/g" /etc/php5/apache2/php.ini && \
    sed -i "s/^track_errors = Off/track_errors = On/g" /etc/php5/apache2/php.ini && \
    sed -i "s/^;error_log = php_errors.log/error_log = \/var\/log\/dockersite\/php_errors.log/g" /etc/php5/apache2/php.ini && \
    sed -i "s/^disable_functions =.*/disable_functions = shell-exec, system, passthru, popen/g" /etc/php5/apache2/php.ini && \
    sed -i "s/^; max_input_vars =.*/max_input_vars = 2000/g" /etc/php5/apache2/php.ini && \
    sed -i "s/^post_max_size =.*/post_max_size = 32M/g" /etc/php5/apache2/php.ini && \
    sed -i "s/^upload_max_filesize =.*/upload_max_filesize = 32M/g" /etc/php5/apache2/php.ini && \
    sed -i "s/^;date\.timezone =.*/date.timezone = 'Europe\/Paris'/g" /etc/php5/apache2/php.ini

# phpmyadmin
RUN echo "Include /etc/phpmyadmin/apache.conf" >> /etc/apache2/apache2.conf && \
    sed -i 's/    \/\/ $cfg\['\''Servers'\''\]\[$i\]\['\''AllowNoPassword'\''\] = TRUE/    $cfg\['\''Servers'\''\]\[$i\]\['\''AllowNoPassword'\''\] = TRUE/g' /etc/phpmyadmin/config.inc.php && \
    sed -i "s/^\$dbuser='phpmyadmin';/\$dbuser='root';/g" /etc/phpmyadmin/config-db.php && \
    sed -i "s/^\$dbpass='.*';/\$dbpass=getenv('MYSQL_FORCED_ROOT_PASSWORD');/g" /etc/phpmyadmin/config-db.php && \
    echo '<?php' > /etc/phpmyadmin/conf.d/devdocker.php && \
    echo '$cfg["MaxNavigationItems"] = 500;' >> /etc/phpmyadmin/conf.d/devdocker.php

# mysql (mariadb)
RUN sed -i "s/^bind-address.*/bind-address = 0.0.0.0/g" /etc/mysql/my.cnf && \
    sed -i "s/^query_cache_limit.*/slow_query_log = 1\nslow_query_log_file = \/var\/log\/dockersite\/mysql-slow.log\nlong_query_time = 2/g" /etc/mysql/my.cnf && \
    sed -i "s/^query_cache_size.*/query_cache_type = 1\nquery_cache_limit = 16M\nquery_cache_size = 256M\nopen_files_limit = 9999\ninnodb_buffer_pool_size = 32M\nmax_allowed_packet = 32M\ninnodb_log_file_size = 32M\n/g" /etc/mysql/my.cnf && \
    sed -i "s/#character-set-server/character-set-server/g" /etc/mysql/conf.d/mariadb.cnf && \
    sed -i "s/#character_set_server/character_set_server/g" /etc/mysql/conf.d/mariadb.cnf && \
    sed -i "s/#collation-server/collation-server/g" /etc/mysql/conf.d/mariadb.cnf && \
    sed -i "s/#collation_server/collation_server/g" /etc/mysql/conf.d/mariadb.cnf && \
    sed -i "s/#default-character-set/default-character-set/g" /etc/mysql/conf.d/mariadb.cnf
COPY perfs.cnf /etc/mysql/conf.d/

# config mail server so websites can send emails
# TODO: catch all outgoing mails
RUN sed -i "s/^dc_eximconfig_configtype='local'/dc_eximconfig_configtype='internet'/g" /etc/exim4/update-exim4.conf.conf && \
    update-exim4.conf

# ssh
RUN sed -i "s/^Port 22/Port 8022/g" /etc/ssh/sshd_config && \
    sed -i "s/^PermitRootLogin without-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
# copy your *readonly* mounted ssh keys and config everytime you login
COPY copy-ssh-config.sh /
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

# hosts
WORKDIR /etc
RUN cp -p hosts hosts.ori

# cleanup
RUN DEBIAN_FRONTEND=noninteractive apt-get -y clean

# fix docker exec -t
RUN echo 'if [ "$TERM" == "dumb" ]; then ' >> /root/.bashrc && \
    echo '    export TERM=xterm' >> /root/.bashrc && \
    echo 'fi' >> /root/.bashrc

# cd /var/www/html at startup
RUN echo 'cd /var/www/html' >> /root/.bashrc

# expose ports
EXPOSE 8022
EXPOSE 80
EXPOSE 443
EXPOSE 3306

# caution: CMD works ok with double quotes (") but not with single quotes (')
COPY run.sh /run.sh
RUN chmod 755 /run.sh
CMD ["/run.sh"]
