#!/bin/bash

IMAGE=alferez/nagios

docker pull $(grep FROM Dockerfile | awk '{print $2}')

cd nagioscore
git checkout master
git pull
cd ..
cd nagios-plugins
git checkout master
git pull
cd ..
cd nrpe
git checkout master
git pull
cd ..

docker build -t $IMAGE --no-cache .
