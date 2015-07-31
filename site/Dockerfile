FROM debian:jessie
MAINTAINER Pierre-Alexis de Solminihac <pa@quai13.com>

# Set the locale
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apt-utils
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install dialog
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install locales-all
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apache2 libapache2-mod-php5 php5-apcu
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

# config apache
RUN a2enmod rewrite
RUN a2enmod headers
RUN a2enmod expires
RUN a2enmod ssl
RUN echo "Servername localhost" >> /etc/apache2/apache2.conf
RUN sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf
RUN sed -i "s/export APACHE_RUN_USER=www-data/export APACHE_RUN_USER=mysql/g" /etc/apache2/envvars
RUN sed -i "s/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=mysql/g" /etc/apache2/envvars

# Workaround for write permission on write to MacOS X volumes
# See https://github.com/boot2docker/boot2docker/pull/534
RUN adduser --no-create-home --disabled-login --gecos "" mysql --uid 1000
RUN usermod -G staff mysql

# installation mariadb en local
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mariadb-server

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

ADD run.sh /run.sh
RUN chmod 755 /run.sh

EXPOSE 80

# cleanup
RUN DEBIAN_FRONTEND=noninteractive apt-get -y clean

# warning : " != '
CMD ["/run.sh"]
