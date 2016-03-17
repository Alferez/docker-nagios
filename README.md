#Nagios 4.1.1
 
 
 Configure:
 
 You have a basic configuration in default_config folder. Extract this file to your local drive and edit.
 When you run this container you need attach this folder.
 
 
 Configure MAIL:
 
 You need edit mail-config files in mail-config folder
 
 
 Usage:
 
 To run container:
 
 docker run --rm -p 80:80 -v /YOUR_CONFIGURATION_FOLDER:/usr/local/nagios/etc --name nagios docker-nagios:latest
 
 
 
