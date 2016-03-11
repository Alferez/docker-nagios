FROM debian:8
MAINTAINER Jose A Alferez <correo@alferez.es>

ENV DEBIAN_FRONTEND noninteractive

#### Configure TimeZone
RUN echo "Europe/Madrid" > /etc/timezone
RUN dpkg-reconfigure tzdata

#### Instalamos dependencias, Repositorios y Paquetes
RUN echo "deb http://httpredir.debian.org/debian jessie-backports main" >> /etc/apt/sources.list
RUN apt-get update -y --fix-missing
RUN apt-get -y upgrade

RUN apt-get install -y --fix-missing wget curl nano apache2 php5-mysql build-essential php5-cgi php5-gd php5-common php5-curl libgd2-xpm-dev openssl libssl-dev xinetd apache2-utils unzip libapache2-mod-php5 php5-cli apache2-mpm-prefork

#### Creamos el usuario
RUN groupadd nagios
RUN groupadd nagcmd
RUN useradd -u 3000 -g nagios -G nagcmd -d /usr/local/nagios -c 'Nagios Admin' nagios
RUN usermod -a -G nagcmd nagios
RUN usermod -G nagcmd www-data


### Instalamos Nagios
WORKDIR /tmp

RUN curl -L -O https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.1.1.tar.gz
RUN tar xvf nagios-4.1.1.tar.gz

WORKDIR /tmp/nagios-4.1.1
RUN ./configure  --prefix=/usr/local/nagios --with-nagios-user=nagios --with-nagios-group=nagios --with-command-user=nagios --with-command-group=nagcmd
RUN make all
RUN make install
RUN make install-commandmode
RUN make install-init
RUN make install-config


RUN /usr/bin/install -c -m 644 sample-config/httpd.conf /etc/apache2/sites-available/nagios.conf

WORKDIR /tmp
RUN rm -rf nagios-4.1.1*


### Instalamos los Plugins
WORKDIR /tmp
RUN curl -L -O http://nagios-plugins.org/download/nagios-plugins-2.1.1.tar.gz
RUN tar zxvf nagios-plugins-2.1.1.tar.gz

WORKDIR /tmp/nagios-plugins-2.1.1
RUN ./configure --with-nagios-user=nagios --with-nagios-group=nagios --with-openssl
RUN make
RUN make install

WORKDIR /tmp 
RUN rm -rf nagios-plugins-2.1.1*



### Instalamos NRPE
WORKDIR /tmp
RUN curl -L -O http://downloads.sourceforge.net/project/nagios/nrpe-2.x/nrpe-2.15/nrpe-2.15.tar.gz
RUN tar zxvf nrpe-2.15.tar.gz

WORKDIR /tmp/nrpe-2.15
RUN ./configure --enable-command-args --with-nagios-user=nagios --with-nagios-group=nagios --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib/x86_64-linux-gnu
RUN make all
RUN make install
RUN make install-xinetd
RUN make install-daemon-config

WORKDIR /tmp
RUN rm -rf nrpe-2.15*

#### Configuramos Apache
RUN echo 'date.timezone = "Europe/Madrid"' >> /etc/php5/apache2/php.ini
RUN a2enmod rewrite
RUN a2enmod cgi
RUN echo "ServerName localhost" | tee /etc/apache2/conf-available/fqdn.conf
RUN ln -s /etc/apache2/conf-available/fqdn.conf /etc/apache2/conf-enabled/fqdn.conf
RUN ln -s /etc/apache2/sites-available/nagios.conf /etc/apache2/sites-enabled/
#RUN sed -i 's|^Alias /nagios|Alias / |g' /etc/apache2/sites-enabled/nagios.conf 
#RUN unlink /etc/apache2/sites-enabled/000-default.conf 


### Configuracion
### Usuario nagiosadmin pass 1234
RUN echo 'nagiosadmin:$apr1$MiSatjLg$viCZy5rD5lbc5mGZ514dE/' > /usr/local/nagios/etc/htpasswd.users



### Limpiamos
RUN apt-get clean
RUN rm -rf /tmp/* /var/tmp/*
RUN rm -rf /var/lib/apt/lists/*

### Add Entrypoing
ADD ./assets/start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /root

ENTRYPOINT "/start.sh"

### Personalizacion
RUN echo "alias l='ls -la'" >> /root/.bashrc
