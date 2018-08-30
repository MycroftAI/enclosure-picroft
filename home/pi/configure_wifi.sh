#!/bin/bash

# Enter the Mycroft venv
source /opt/venvs/mycroft-core/bin/activate

# Send a message to start the wifi setup process
output=$(python -m mycroft.messagebus.send "mycroft.wifi.start")

echo "====================================================================="
echo "Wifi setup has begun.  Use your phone, tablet or laptop to connect to"
echo "the network 'MYCROFT' using the password '12345678'.  Once connected"
echo "browse to 'https://start.mycroft.ai', then follow the prompts to"
echo "complete the setup."
echo "====================================================================="
