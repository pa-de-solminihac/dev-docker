FROM debian:jessie
MAINTAINER Pierre-Alexis de Solminihac <pa@quai13.com>


#####################
# ENABLE REPOSITORIES
#####################

# choose a faster mirror
#COPY sources.list /etc/apt/sources.list

# enable docker repository
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apt-transport-https ca-certificates
#RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && \
#    echo "deb https://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list

# enable blackfire.io additional repository
ADD https://packagecloud.io/gpg.key /tmp/blackfire.key
RUN DEBIAN_FRONTEND=noninteractive apt-key add /tmp/blackfire.key && \
    echo "deb http://packages.blackfire.io/debian any main" | tee /etc/apt/sources.list.d/blackfire.list

# enable debian jessie backports
RUN echo "deb http://httpredir.debian.org/debian jessie-backports main" | tee /etc/apt/sources.list.d/backports.list

# enable dotdeb repository
#ADD https://www.dotdeb.org/dotdeb.gpg /tmp/dotdeb.key
#RUN DEBIAN_FRONTEND=noninteractive apt-key add /tmp/dotdeb.key && \
#    echo "deb http://packages.dotdeb.org jessie all" | tee /etc/apt/sources.list.d/dotdeb.list

##################
# INSTALL PACKAGES
##################

# install required packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update
#RUN DEBIAN_FRONTEND=noninteractive apt-get -y install docker-engine
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apt-utils
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install dialog
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install locales-all
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install net-tools dnsutils whois strace
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install sudo
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install memcached
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apache2
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install libapache2-mod-php5
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-apcu
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-memcache
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-memcached
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-intl
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-mysqlnd
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-pgsql
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-json
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-xsl
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-imap
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-curl
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-gd
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-imagick
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php-gettext
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php5-oauth
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install php-pear
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install bash bash-completion
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install ncdu ncurses-bin
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install vim nano
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install grep ack-grep silversearcher-ag
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install git
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mariadb-client
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install openssh-server openssh-client rsync
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install lynx curl wget netcat whatweb
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install phpmyadmin
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install man-db manpages
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install blackfire-agent blackfire-php
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mariadb-server
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mailutils
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install drush
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install build-essential autoconf pkg-config nasm libtool
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install rsyslog
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install imagemagick
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install ssl-cert
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install unzip unrar-free p7zip-full

# install libreoffice from backports
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install openjdk-7-jre
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install -t jessie-backports libreoffice-writer

# install letsencrypt from backports
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install -t jessie-backports python-certbot-apache

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install trash-cli

#################################
# WORKAROUND for write permission
#################################

# See https://github.com/boot2docker/boot2docker/pull/534
ENV USER_ID=9999
ENV GROUP_ID=9999
RUN addgroup devdocker --gid $GROUP_ID
RUN adduser --disabled-login --gecos "devdocker" devdocker --uid $USER_ID --gid $GROUP_ID
RUN echo "devdocker ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/devdocker && \
    chmod 440 /etc/sudoers.d/devdocker


##########################
# INSTALL WITHOUT PACKAGES
##########################

# composer
WORKDIR /usr/local/bin
RUN curl -s "https://getcomposer.org/installer" | php && mv composer.phar /usr/local/bin/composer

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

# other image optimisation tools
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install jpegoptim gifsicle optipng pngquant

ARG CACHEBUST=1

# install wp-wned.sh
COPY wp-wned.sh /usr/local/bin/

# install wp-cli
WORKDIR /usr/local/bin
RUN curl -O "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar wp

# install php beautifiers
WORKDIR /usr/local/bin
RUN wget http://get.sensiolabs.org/php-cs-fixer.phar -O php-cs-fixer && \
    chmod a+x php-cs-fixer
RUN pear install PHP_Beautifier-0.1.15
RUN git clone https://github.com/pa-de-solminihac/php-auto-indent.git /usr/local/src/php-auto-indent && \
    chmod a+x /usr/local/src/php-auto-indent && \
    ln -s /usr/local/src/php-auto-indent/php-auto-indent /usr/local/bin

# install cdiff
WORKDIR /usr/local/src/
RUN git clone https://github.com/ymattw/cdiff.git && \
    cd cdiff && \
    ./setup.py install

# install sitesync
RUN git clone https://github.com/pa-de-solminihac/sitesync.git /sitesync && \
    chmod -R 777 /sitesync/tmp && \
    chmod -R 777 /sitesync/log
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
WORKDIR /home/devdocker/
RUN cp -pr /root/configuration /home/devdocker/ && \
    chown -R devdocker: configuration && \
    echo "source /home/devdocker/.bashrc_local" >> /home/devdocker/.bashrc && \
    ln -s /home/devdocker/configuration/bash/.bashrc_local && \
    ln -s /home/devdocker/configuration/bash/.bashrc_common && \
    echo "source /home/devdocker/.vimrc_common" >> /home/devdocker/.vimrc && \
    ln -s /home/devdocker/configuration/vim/.vimrc_common && \
    mkdir -p bin && \
    ln -s /home/devdocker/configuration/bin/diffconflicts bin/


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
COPY gitconfig /home/devdocker/.gitconfig

# configure blackfire
COPY blackfire-agent /etc/blackfire/agent
COPY blackfire-client /home/devdocker/.blackfire.ini

# apache
COPY 000-default.conf /etc/apache2/sites-enabled/
RUN make-ssl-cert generate-default-snakeoil
RUN a2enmod rewrite && \
    a2enmod headers && \
    a2enmod expires && \
    a2enmod include && \
    a2enmod ssl && \
    a2enmod vhost_alias && \
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
RUN sed -i "s/export APACHE_RUN_USER=www-data/export APACHE_RUN_USER=devdocker/g" /etc/apache2/envvars && \
    sed -i "s/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=devdocker/g" /etc/apache2/envvars && \
    chgrp devdocker /var/lib/phpmyadmin/* /etc/phpmyadmin/config-db.php /etc/phpmyadmin/htpasswd.setup

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
    echo '$cfg["MaxNavigationItems"] = 500;' >> /etc/phpmyadmin/conf.d/devdocker.php && \
    echo '$sessionDuration = 60*60*24*7; // 60*60*24*7 = one week' >> /etc/phpmyadmin/conf.d/devdocker.php && \
    echo 'ini_set("session.gc_maxlifetime", $sessionDuration);' >> /etc/phpmyadmin/conf.d/devdocker.php && \
    echo '$cfg["LoginCookieValidity"] = $sessionDuration;' >> /etc/phpmyadmin/conf.d/devdocker.php

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
RUN mkdir -p /home/devdocker/.ssh && chmod 700 /home/devdocker/.ssh

# allow docker to run without sudo
#RUN gpasswd -a devdocker docker

# cleanup
RUN DEBIAN_FRONTEND=noninteractive apt-get -y clean

# fix docker exec -t
RUN echo 'if [ "$TERM" == "dumb" ]; then ' >> /home/devdocker/.bashrc && \
    echo '    export TERM=xterm' >> /home/devdocker/.bashrc && \
    echo 'fi' >> /home/devdocker/.bashrc

# cd /var/www/html at startup
RUN echo 'cd /var/www/html' >> /home/devdocker/.bashrc

# longer log messages
RUN echo '$MaxMessageSize 20k' > /etc/rsyslog.d/devdocker.conf

# start ssh-agent at startup
RUN echo 'if [ "$(pgrep ssh-agent)" == "" ]; then SSHAGENTEVAL="$(ssh-agent -s)"; echo "$SSHAGENTEVAL" | grep -v echo >> /home/devdocker/.bashrc; eval "$SSHAGENTEVAL"; fi' >> /home/devdocker/.bashrc

# source custom bashrc file at startup
RUN echo "for f in \$(find /home/devdocker/bashrc.d -maxdepth 1 -type f -name '*.sh'); do source \$f; done" >> /home/devdocker/.bashrc

RUN echo '' > /etc/motd

RUN echo devdocker:devdocker | chpasswd

# expose ports
EXPOSE 8022
EXPOSE 80
EXPOSE 443
EXPOSE 3306

# caution: CMD works ok with double quotes (") but not with single quotes (')
COPY run.sh /run.sh
RUN chmod 755 /run.sh
CMD ["/run.sh"]
