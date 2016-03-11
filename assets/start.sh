#!/bin/bash

echo "Starting Apache...."
service apache2 start

echo "Starting Nagios...."
service nagios start
service xinetd start

while true
do
	sleep 1
done

