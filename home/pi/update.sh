#!/bin/bash

##########################################################################
# udpate.sh
##########################################################################
# This script is executed by the auto_run.sh when a new version is found
# at github.com/MycroftAI/enclosure-picroft

cd ~
wget https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/auto_run.sh
wget https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/README
wget https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/configure_wifi.sh
wget https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/messagebus_emit.py
wget https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/say_command.py

cd ~/bin
wget https://raw.githubusercontent.com/MycroftAI/mycroft-core/master/msm/msm
wget https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/bin/cli
wget https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/bin/say
wget https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/bin/test_microphone
wget https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/bin/view_log

