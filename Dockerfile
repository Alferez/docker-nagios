FROM debian:11
MAINTAINER Jose A Alferez <correo@alferez.es>

ENV DEBIAN_FRONTEND noninteractive

#### Configure TimeZone
RUN echo "Europe/Madrid" > /etc/timezone
RUN dpkg-reconfigure tzdata

#### Instalamos dependencias, Repositorios y Paquetes
RUN echo "deb http://httpredir.debian.org/debian bullseye-backports main" >> /etc/apt/sources.list && apt-get update -y --fix-missing && apt-get -y upgrade

RUN apt-get install -y --fix-missing wget curl nano apache2 php-mysql build-essential php-cgi php-gd php-common php-curl libgd-dev openssl libssl-dev xinetd apache2-utils unzip libapache2-mod-php php-cli  make mosquitto-clients bc dnsutils m4 gettext automake autoconf net-tools mariadb-client iputils-ping gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext libdbi-dev libldap2-dev dnsutils smbclient fping libmariadb-dev libmariadb-dev-compat

#### Creamos el usuario
RUN groupadd nagios && groupadd nagcmd && useradd -u 3000 -g nagios -G nagcmd -d /usr/local/nagios -c 'Nagios Admin' nagios && usermod -a -G nagcmd nagios && usermod -G nagcmd www-data

### Instalamos Nagios
COPY ./nagioscore /tmp/nagioscore

WORKDIR /tmp/nagioscore
RUN ./configure  --prefix=/usr/local/nagios --with-nagios-user=nagios --with-nagios-group=nagios --with-command-user=nagios --with-command-group=nagcmd
RUN make all && make install && make install-commandmode && make install-init && make install-config

RUN /usr/bin/install -c -m 644 sample-config/httpd.conf /etc/apache2/sites-available/nagios.conf

### Instalamos los Plugins
COPY ./nagios-plugins /tmp/nagios-plugins
WORKDIR /tmp/nagios-plugins
RUN ./tools/setup && ./configure --with-nagios-user=nagios --with-nagios-group=nagios --with-openssl && make && make install && make install-root

### Instalamos NRPE
COPY ./nrpe /tmp/nrpe

WORKDIR /tmp/nrpe
RUN ./configure --enable-command-args --with-nagios-user=nagios --with-nagios-group=nagios --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib/x86_64-linux-gnu && make all && make install

WORKDIR /tmp
RUN rm -rf nrpe nagios nagios-plugins nagioscore

#### Configuramos Apache
RUN a2enmod rewrite cgi auth_form session_cookie session_crypto request && echo "ServerName localhost" | tee /etc/apache2/conf-available/fqdn.conf && ln -s /etc/apache2/conf-available/fqdn.conf /etc/apache2/conf-enabled/fqdn.conf && ln -s /etc/apache2/sites-available/nagios.conf /etc/apache2/sites-enabled/

### Configuracion
### Usuario nagiosadmin pass 1234
COPY ./default-config/default_confg.tar.gz /tmp/default_confg.tar.gz
RUN tar zxvf /tmp/default_confg.tar.gz && rm -rf /usr/local/nagios/etc && mv /tmp/etc /usr/local/nagios

#### Optionals Modules
RUN apt-get update -y --fix-missing && apt-get install -y libb-utils-perl libstring-random-perl python  libio-socket-ssl-perl libxml-simple-perl snmp python3-axolotl python3-dateutil python3-setuptools python3-dev libffi-dev libssl-dev libmonitoring-plugin-perl python3-pip make libperl-dev libparams-validate-perl libmath-calc-units-perl libclass-accessor-perl libconfig-tiny-perl git libnet-snmp-perl
RUN pip3 install twx.botapi urllib3 pyopenssl
WORKDIR /tmp
RUN git clone https://github.com/nagios-plugins/nagios-plugin-perl.git
WORKDIR /tmp/nagios-plugin-perl
RUN perl Makefile.PL && make && make test && make install

### Personalizacion
RUN echo "alias l='ls -la'" >> /root/.bashrc && echo "export TERM=xterm" >> /root/.bashrc && wget https://www.alferez.es/nagios_logos/dockerbyalferez.png -O /usr/local/nagios/share/images/dockerbyalferez.png && wget https://www.alferez.es/nagios_logos/sblogo.png -O /usr/local/nagios/share/images/sblogo.png && wget https://www.alferez.es/nagios_logos/logofullsize.png -O /usr/local/nagios/share/images/logofullsize.png && wget https://www.alferez.es/nagios_logos/corelogo.gif -O /usr/local/nagios/share/images/corelogo.gif && sed -i '/<div class="logos">/a\                <a href="https:\/\/www.alferez.es\/" target="_blank"><img src="images\/dockerbyalferez.png" width="110" height="50" border="1" alt="Alferez.es" \/><\/a>' /usr/local/nagios/share/main.php && sed -i 's/sblogo.png" height="39"/sblogo.png" height="52"/g' /usr/local/nagios/share/side.php

### Fix Mail Sender
RUN apt-get remove --purge -y exim4* && apt-get install -y --fix-missing postfix && apt-get install -y --fix-missing mailutils && postconf -e mynetworks="0.0.0.0/0" 
ENV ROOT_EMAIL=nagios@nagiossystem.com
ENV MAILNAME=nagios.nagiossystem.com
RUN postconf -e myhostname=$MAILNAME && echo $MAILNAME > /etc/mailname && echo root: $ROOT_EMAIL >> /etc/aliases && /usr/bin/newaliases

### Limpiamos
RUN apt-get autoremove -y && apt-get clean && rm -rf /tmp/* /var/tmp/* && rm -rf /var/lib/apt/lists/*

### Add Entrypoing
COPY ./assets/start.sh /start.sh
RUN chmod +x /start.sh
WORKDIR /root
ENTRYPOINT "/start.sh"
