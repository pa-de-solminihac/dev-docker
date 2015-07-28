FROM alpine:latest
MAINTAINER Pierre-Alexis de Solminihac <pa@quai13.com>

# Set the locale
RUN \
    apk add --update \
        apache2 php-apache2 php-apcu \
        php-intl php-iconv php-gettext \
        php-mysql php-mysqli php-pgsql php-pdo php-pdo_mysql php-pdo_pgsql \
        php-openssl \
        php-json \
        php-zlib \
        php-imap php-curl php-gd \
        bash bash-completion docker-bash-completion git-bash-completion \
        ncdu vim vimdiff ncurses \
        grep perl ack \
        git \
        mysql-client \
        \openssh-client rsync \
        lynx && \
    rm -fr /var/cache/apk/*

# Workaround for write permission on write to MacOS X volumes
# See https://github.com/boot2docker/boot2docker/pull/534
#RUN usermod -u 1000 www-data
RUN adduser -H -D -u 1000 docker_site
RUN addgroup -g 50 group_docker_site

# config apache
RUN echo "Servername localhost" >> /etc/apache2/httpd.conf
RUN sed -i "s/User apache/User docker_site/g" /etc/apache2/httpd.conf
RUN sed -i "s/Group apache/Group group_docker_site/g" /etc/apache2/httpd.conf

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

