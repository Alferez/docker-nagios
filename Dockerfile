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

COPY ./nagioscore /tmp/nagioscore

WORKDIR /tmp/nagioscore
RUN ./configure  --prefix=/usr/local/nagios --with-nagios-user=nagios --with-nagios-group=nagios --with-command-user=nagios --with-command-group=nagcmd
RUN make all
RUN make install
RUN make install-commandmode
RUN make install-init
RUN make install-config


RUN /usr/bin/install -c -m 644 sample-config/httpd.conf /etc/apache2/sites-available/nagios.conf

WORKDIR /tmp
RUN rm -rf nagios

RUN apt-get install -y --fix-missing  m4 gettext automake autoconf

### Instalamos los Plugins
#WORKDIR /tmp
COPY ./nagios-plugins /tmp/nagios-plugins
#RUN wget $(curl https://www.nagios.org/downloads/nagios-plugins/ | grep "/download/"| awk -F'href=' '{print $2}' | awk -F'"' '{print $2}')
#RUN tar zxvf nagios-plugins*
WORKDIR /tmp/nagios-plugins
RUN ./tools/setup
RUN ./configure --with-nagios-user=nagios --with-nagios-group=nagios --with-openssl
RUN make
RUN make install
RUN make install-root

WORKDIR /tmp 
RUN rm -rf nagios-plugins



### Instalamos NRPE
WORKDIR /tmp
COPY ./nrpe /tmp/nrpe

WORKDIR /tmp/nrpe
RUN ./configure --enable-command-args --with-nagios-user=nagios --with-nagios-group=nagios --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib/x86_64-linux-gnu
RUN make all
RUN make install
#RUN make install-xinetd
#RUN make install-daemon-config

WORKDIR /tmp
RUN rm -rf nrpe

#### Configuramos Apache
RUN echo 'date.timezone = "Europe/Madrid"' >> /etc/php5/apache2/php.ini
RUN a2enmod rewrite
RUN a2enmod cgi
RUN echo "ServerName localhost" | tee /etc/apache2/conf-available/fqdn.conf
RUN ln -s /etc/apache2/conf-available/fqdn.conf /etc/apache2/conf-enabled/fqdn.conf
RUN ln -s /etc/apache2/sites-available/nagios.conf /etc/apache2/sites-enabled/


### Configuracion
### Usuario nagiosadmin pass 1234
COPY ./default-config/default_confg.tar.gz /tmp/default_confg.tar.gz
RUN tar zxvf /tmp/default_confg.tar.gz
RUN rm -rf /usr/local/nagios/etc
RUN mv /tmp/etc /usr/local/nagios

#### Optionals Modules
RUN apt-get update -y --fix-missing
RUN apt-get install -y libnagios-plugin-perl libb-utils-perl libstring-random-perl python  libio-socket-ssl-perl libxml-simple-perl

RUN apt-get install -y snmp

### Personalizacion
RUN echo "alias l='ls -la'" >> /root/.bashrc
RUN echo "export TERM=xterm" >> /root/.bashrc

### Fix MTA
#RUN mkdir /usr/local/nagios/etc/mail-config
#RUN mv /etc/exim4/update-exim4.conf.conf /usr/local/nagios/etc/mail-config
#RUN mv /etc/exim4/passwd.client /usr/local/nagios/etc/mail-config
RUN rm /etc/exim4/update-exim4.conf.conf /etc/exim4/passwd.client
RUN ln -s /usr/local/nagios/etc/mail-config/update-exim4.conf.conf /etc/exim4/update-exim4.conf.conf
RUN ln -s /usr/local/nagios/etc/mail-config/passwd.client /etc/exim4/passwd.client      

### Limpiamos
RUN apt-get clean
RUN rm -rf /tmp/* /var/tmp/*
RUN rm -rf /var/lib/apt/lists/*

### Add Entrypoing
COPY ./assets/start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /root

ENTRYPOINT "/start.sh"
