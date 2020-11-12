#Nagios 4.X
 
 
 Configure:
 
 You have a basic configuration in default_config folder. Extract this file to your local drive and edit.
 When you run this container you need attach this folder.
 
 
 Configure MAIL:
 
 You need edit file notification.cfg in config.d/commands.d folder with your configuration data.
 
 Usage:
 
 To run container:
 
 docker run --rm -p 80:80 -v /YOUR_CONFIGURATION_FOLDER:/usr/local/nagios/etc --name nagios alferez/nagios:latest
 
 
You can see the full article at in <a href="https://www.alferez.es/monitorizacion/usando-nagios-docker/"> Monitorizando con Nagios y docker </a>
