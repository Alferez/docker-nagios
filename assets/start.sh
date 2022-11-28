#!/bin/bash

echo "Starting Syslog..."
service rsyslog start
sleep 1

echo "Starting Postfix..."
if [ "$ROOT_EMAIL" != "nagios@nagiossystem.com" ]
then
	echo "    setting root_email."
	sed -i '/nagios@nagiossystem.com/d' /etc/aliases
	echo root: $ROOT_EMAIL >> /etc/aliases
	/usr/bin/newaliases
fi

if [ "$MAILNAME" != "nagios.nagiossystem.com" ]
then
	echo "    setting mailname."
	postconf -e myhostname=$MAILNAME
	echo $MAILNAME > /etc/mailname
fi

service postfix start
sleep 5

echo "Starting Apache...."
service apache2 start

echo "Starting Nagios...."
service nagios start
service xinetd start

while true
do
	sleep 1
done
