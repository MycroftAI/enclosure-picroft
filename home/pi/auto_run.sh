#!/bin/bash
##########################################################################
# auto_run.sh
##########################################################################
# This script is executed by the .bashrc every time someone logs in to the
# system.

######################
# Comamnd line helpers
export PATH="$HOME/bin:$PATH"

echo ""
echo "***********************************************************************"
echo "** Picroft development image, ver" $(<version)
echo "***********************************************************************"
echo "This image is designed to make getting started with Mycroft easy.  It"
echo "is pre-configured for a Raspberry Pi that has a speaker or headphones"
echo "plugged in to the Pi's headphone jack, and a USB microphone."
echo "***********************************************************************"

if [ "$SSH_CLIENT" == "" ]
then
   # running at the local console (e.g. plugged into the HDMI output)

   # Make sure the audio is being output via the correct device.  You can
   # change this to match your usage in audio_setup.sh, the default is
   # to output from the headphone jack.
   #
   sudo amixer cset numid=3 "1"   # audio out the analog speaker/headphone jack
   amixer set Master 75% # set volume to a reasonable level

   # Do not edit this script (it may be replaced later by the update process),
   # but you can edit and customize the audio_setup.sh and custom_setup.sh
   # script.  Use the audio_setup.sh to change audio output configuration and
   # default volume; use custom_setup.sh to initialize any other IoT devices.
   #
   # Check for custom audio setup
   if [ -f audio_setup.sh ]
   then
      source audio_setup.sh
   fi

   # Check for custom Device setup
   if [ -f custom_setup.sh ]
   then
      source custom_setup.sh
   fi

   # Upgrade if connected to the internet and one is available
   ping -q -c 1 -W 1 google.com >/dev/null 2>&1
   if [ $? -eq 0 ]
   then
      echo "Checking for updates to Picroft environment"
      cd /tmp
      wget -N https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/version
      if [ $? -eq 0 ]
      then
         if [ ! -f ~/version ]
         then
            echo "unknown" > ~/version
         fi

         cmp /tmp/version ~/version
         if  [ $? -eq 1 ]
         then
            # Versions don't match...update needed
            echo "Updating Picroft scripts!"
            speak "Updating Picroft, please hold on."
            wget -N https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/master/home/pi/update.sh
            source update.sh
            cp /tmp/version ~/version

            # restart
            echo "Rebooting now"
            speak "Update complete, restarting."
            sudo reboot now
         fi
      fi

      echo "Checking for updates to Mycroft-core..."
      sudo apt-get update -o Dir::Etc::sourcelist="sources.list.d/repo.mycroft.ai.list" \
                     -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
      sudo apt-get install --only-upgrade mycroft-core mimic -y
   fi
   echo ""
   echo "========================================"
   python -c "import mycroft.version; print 'Mycroft Core Version: '+mycroft.version.CORE_VERSION_STR"
   echo "========================================"


   # TODO: I am not sure why the following is needed, but things don't start
   #       correctly without this restart workaround.
   echo "Starting up services"
   sleep 10
   sudo service mycroft-speech-client restart
   sleep 5

   # check to see if the unit is connected to the internet.
   if ! ping -q -c 1 -W 1 google.com >/dev/null 2>&1
   then
      echo "Internet connection not detected, starting WIFI setup process..."
      source configure_wifi.sh &
      # Wait for an internet connection -- either the user finished Wifi Setup or
      # plugged in a network cable.
      while ! ping -q -c 1 -W 1 8.8.8.8 >/dev/null 2>&1 ; do
         sleep 1
      done

      echo "Internet connection detected!"
      echo "Restarting..."
      speak "Restarting now."
      sudo reboot now
   fi


   # check to see if the unit has been registered yet
   IDENTITY_FILE="/home/mycroft/.mycroft/identity/identity2.json"
   if [ -f $IDENTITY_FILE ]
   then
      IDENTITY_FILE_SIZE=$(stat -c%s $IDENTITY_FILE)
   else
      IDENTITY_FILE_SIZE=0
   fi

   echo ""
   if [ $IDENTITY_FILE_SIZE -lt 100 ]
   then
      # this invokes the pairing process
      echo "This unit needs to be registered.  Use your computer or mobile device"
      echo "to browse to https://home.mycroft.ai and enter the pairing code"
      echo "displayed below."
      sleep 2
      say_to_mycroft "pair my device" >/dev/null 2>&1 &
   else
      echo "Mycroft is currently running in the background, so you can say"
      echo "'Hey Mycroft' to activate it. Try saying 'Hey Mycroft, what time is it'"
      echo "to test the system."
   fi
else
   # running from a SSH session
   echo "Remote session"
fi


sleep 2
echo ""
echo "***********************************************************************"
echo "In a few moments you will see the contents of the speech log.  Hit"
echo "Ctrl+C to stop showing the log and return to the command line.  You will"
echo "still be able to speak to Mycroft after that, only the display of the"
echo "log will cease.  To see the live log again, type:"
echo "    view_log"
echo ""
echo "Additional commands you can use from the command line:"
echo "    msm - Mycroft Skills Manager, install new Skills from Github"
echo "    cli - command line client"
echo "    say_to_mycroft - one-shot commands from the command line"
echo "    speak - say something to the user"
echo "    test_microphone - record and playback to test your microphone"
echo "***********************************************************************"
echo ""
echo ""
sleep 2
tail -f /var/log/mycroft-speech-client.log
