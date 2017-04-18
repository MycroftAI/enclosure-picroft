#!/bin/bash

##########################################################################
# udpate.sh
##########################################################################
# This script is executed by the auto_run.sh when a new version is found
# at github.com/MycroftAI/enclosure-picroft

cd ~
wget -N https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/.bashrc
wget -N https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/README
wget -N https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/auto_run.sh
wget -N https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/configure_wifi.sh
wget -N https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/messagebus_emit.py
wget -N https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/say_command.py

cd ~/bin
wget -N https://raw.githubusercontent.com/MycroftAI/mycroft-core/master/msm/msm
wget -N https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/bin/cli
wget -N https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/bin/say_to_mycroft
wget -N https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/bin/speak
wget -N https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/bin/test_microphone
wget -N https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/bin/view_log
chmod +x *

# Cleanup post-upgrade
if [ -f say ]
then
   rm say
fi

cd ~