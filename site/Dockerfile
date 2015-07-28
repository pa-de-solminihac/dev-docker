FROM debian:jessie
MAINTAINER Pierre-Alexis de Solminihac <pa@quai13.com>

# Set the locale
RUN apt-get update
RUN apt-get -y install apache2 libapache2-mod-php5 php5-apcu # php-opcache
RUN apt-get -y install php5-intl php-gettext # php-iconv
RUN apt-get -y install php5-mysqlnd php5-pgsql # php-pdo php-pdo_mysql php-pdo_pgsql php5-mysql
# RUN apt-get -y install php-openssl
RUN apt-get -y install php5-json php5-xsl # php-xml
#RUN apt-get -y install php-zlib
RUN apt-get -y install php5-imap php5-curl php5-gd
RUN apt-get -y install bash bash-completion # docker-bash-completion git-bash-completion
RUN apt-get -y install ncdu vim ncurses-bin # vimdiff
RUN apt-get -y install grep ack-grep # perl
RUN apt-get -y install git
RUN apt-get -y install mysql-client
RUN apt-get -y install openssh-client rsync
RUN apt-get -y install lynx
RUN apt-get clean

# Workaround for write permission on write to MacOS X volumes
# See https://github.com/boot2docker/boot2docker/pull/534
#RUN usermod -u 1000 www-data
RUN adduser --no-create-home --disabled-login --gecos "" docker_site # --uid 1000 
RUN addgroup group_docker_site # --gid 50

# config apache
RUN echo "Servername localhost" >> /etc/apache2/apache2.conf
RUN sed -i "s/export APACHE_RUN_USER=www-data/export APACHE_RUN_USER=docker_site/g" /etc/apache2/envvars
RUN sed -i "s/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=group_docker_site/g" /etc/apache2/envvars

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

#RUN apt-get install locales
#RUN locale-gen en_US.UTF-8
#RUN locale-gen fr_FR.UTF-8

# Install PDO MySQL driver
# See https://github.com/docker-library/php/issues/62
#RUN docker-php-ext-install pdo mysql
#RUN apt-get install -y libapache2-mod-php5
#RUN service apache2 restart

# Enable Apache mod_rewrite
#RUN a2enmod rewrite

ADD run.sh /run.sh
RUN chmod 755 /run.sh

EXPOSE 80

# attention ici à bien utiliser des " et non des ' sinon ça ne marche tout simplement pas...
CMD ["/run.sh"]

