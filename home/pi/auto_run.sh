#!/bin/bash
##########################################################################
# auto_run.sh
##########################################################################
# This script is executed by the .bashrc every time someone logs in to the
# system.

# Do not edit this script (it may be replaced later by the update process),
# but you can edit and customize the audio_setup.sh and custom_setup.sh
# script.  Use the audio_setup.sh to change audio output configuration and
# default volume; use custom_setup.sh to initialize any other IoT devices.
#

export PATH="$HOME/bin:$PATH"

function network_setup() {
   # silent check at first
   if ping -q -c 1 -W 1 8.8.8.8 >/dev/null 2>&1 ; then
      return 0
   fi

   # Wait for an internet connection -- either the user finished Wifi Setup or
   # plugged in a network cable.
   show_prompt=1
   should_reboot=255
   while ! ping -q -c 1 -W 1 8.8.8.8 >/dev/null 2>&1 ; do
      if [ $show_prompt = 1 ] ; then
         echo "Network connection not found, press a key to setup via keyboard"
         echo "or plug in a network cable:"
         echo "  1) Basic wifi with SSID and password"
         echo "  2) Wifi with no password"
         echo "  3) TODO: Advanced wifi"
         echo "  4) Edit wpa_supplicant.conf directly"
         echo "  5) Force reboot"
         echo "  6) Skip network setup for now"
         echo -n "Choice [1-6]: "
         show_prompt=0
      fi

      read -N1 -s -t 1 pressed

      case $pressed in
         1)
            echo ""
            echo -n "Enter a network SSID: "
            read user_ssid
            echo -n "Enter the password: "
            read -s user_pwd
            echo ""
            echo -n "Enter the password again: "
            read -s user_confirm
            echo ""

            if [[ "$user_pwd" = "$user_confirm" && "$user_ssid" != "" ]]
            then
               echo "network={" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
               echo "        ssid=\"$user_ssid\"" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
               echo "        psk=\"$user_pwd\"" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
               echo "}" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
               should_reboot=1
               break
            else
               show_prompt=1
            fi
            ;;
         2)
            echo ""
            echo -n "Enter a network SSID: "
            read user_ssid

            if [ ! "$user_ssid" = "" ]
            then
               echo "network={" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
               echo "        ssid=\"$user_ssid\"" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
               echo "        key_mgmt=NONE" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
               echo "}" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
               should_reboot=1
               break
            else
               show_prompt=1
            fi
            ;;
         3)
            echo ""
            echo "TODO: Options for WPA 2 Ent, etc"
            # See:  https://github.com/MycroftAI/enclosure-picroft/blob/master/setup_eap_wifi.sh
            # See also:  https://w1.fi/cgit/hostap/plain/wpa_supplicant/wpa_supplicant.conf
            break
            ;;
         4)
            sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
            should_reboot=1
            break
            ;;
         5)
            should_reboot=1
            break
            ;;
         6)
            should_reboot=0
            break;
            ;;
      esac
   done

   if [[ $should_reboot -eq 255 ]]
   then
      # Auto-detected
      echo ""
      echo "Network connection detected!"
      should_reboot=0
   fi

   return $should_reboot
}

function setup_wizard() {

   # Handle internet connection
   network_setup
   if [[ $? -eq 1 ]]
   then
      echo "Rebooting..."
      sudo reboot
   fi

   echo ""
   echo "How do you want Mycroft to output audio:"
   echo "  1) Speakers via 3.5mm output (aka 'audio jack' or 'headphone jack')"
   echo "  2) HDMI audio (e.g. a TV or monitor with built-in speakers)"
   echo "  3) USB audio (e.g. a USB soundcard or USB mic/speaker combo)"
   echo -n "Choice [1-3]: "
   while true; do
      read -N1 -s key
      case $key in
         [1])
            echo "$key - Analog audio"
            # audio out the analog speaker/headphone jack
            sudo amixer cset numid=3 "1" > /dev/null
            echo 'sudo amixer cset numid=3 "1"' >> ~/audio_setup.sh
            break
            ;;
         [2])
            echo "$key - HDMI audio"
            # audio out the HDMI port (e.g. TV speakers)
            sudo amixer cset numid=3 "2" > /dev/null
            echo 'sudo amixer cset numid=3 "2"' >> ~/audio_setup.sh
            break
            ;;
         [3])
            echo "$key - USB audio"
            # audio out to the USB soundcard
            sudo amixer cset numid=3 "0" > /dev/null
            echo 'sudo amixer cset numid=3 "0"' >> ~/audio_setup.sh
            break
            ;;
      esac
   done

   lvl=7
   echo ""
   echo "Let's test and adjust the volume:"
   echo "  1-9) Set volume level (1-quietest, 9=loudest)"
   echo "  T)est"
   echo "  R)eboot (might be needed if you just plugged in a USB speaker)"
   echo "  D)one!"
   while true; do
      echo -n -e "\rLevel [1-9/T/D/R]: ${lvl}          \b\b\b\b\b\b\b\b\b\b"
      read -N1 -s key
      case $key in
        [1-9])
           lvl=$key
           # Set volume between 19% and 99%.  Lazily not allowing 100% :)
           amixer set PCM "${lvl}9%" > /dev/null
           echo -e -n "\b$lvl PLAYING"
           speak "Test"
           ;;
        [Rr])
           echo "Rebooting..."
           sudo reboot
           ;;
        [Tt])
           amixer set PCM '${lvl}9%' > /dev/null
           echo -e -n "\b$lvl PLAYING"
           speak "Test"
           ;;
        [Dd])
           echo " - Saving"
           break
           ;;
      esac
   done
   echo "amixer set PCM "$lvl"9%" >> ~/audio_setup.sh

   echo ""
   echo "Final step: testing your microphone."
   echo "TODO: Something interactive"
   echo ""

   echo "Hardware setup is complete.  Now we'll pull down the latest software updates"
   echo "and start Mycroft.  You'll be prompted to pair this device with an account at"
   echo "https://home.mycroft.ai, then you'll be set to enjoy your Picroft!"
   echo ""
   echo "To rerun this setup, type 'touch first_run' and reboot."
   echo ""
   echo "Press any key to continue..."
   read -N1 -s anykey
}

######################
# mycroft_core_ver=$(python -c "import mycroft.version; print 'mycroft-core: '+mycroft.version.CORE_VERSION_STR" | grep "core:")


echo ""
echo "***********************************************************************"
echo "** Picroft enclosure platform version:" $(<version)
echo "**                       $mycroft_core_ver"
echo "***********************************************************************"

if [ -f ~/first_run ]
then
   echo "Welcome to Picroft!  This image is designed to make getting started with"
   echo "Mycroft quick and easy.  Would you like help setting up your system?"
   echo "  Y)es, I'd like to setup via a series of questions."
   echo "  N)ope, just get me a command line and get out of my way!"
   echo -n "Choice [Y/N]: "
   while true; do
      read -N1 -s key
      case $key in
         [Nn])
            echo $key
            echo ""
            echo "Alright, have fun!"
            echo "NOTE: If you decide to use the wizard later, just type 'touch first_run'"
            echo "      and reboot."
            break
            ;;
         [Yy])
            echo $key
            echo ""
            setup_wizard
            break
            ;;
      esac
   done

   # Delete to flag setup is complete
   rm ~/first_run
fi

# UNCOMMENT WHEN TESTING
# touch ~/first_run
# return


if [ "$SSH_CLIENT" == "" ] && [ "$(/usr/bin/tty)" = "/dev/tty1" ];
then
   # running at the local console (e.g. plugged into the HDMI output)

   # Make sure the audio is being output reasonably.  This can be set
   # to match user preference in audio_setup.sh.  DON'T EDIT HERE,
   # the script will likely be overwritten during later updates.
   #
   # Default to analog audio jack at 75% volume
   sudo amixer cset numid=3 "1" > /dev/null
   amixer set PCM 75% > /dev/null

   # Check for custom audio setup
   if [ -f audio_setup.sh ]
   then
      source audio_setup.sh
      cd ~
   fi

   # verify network settings
   network_setup
   if [[ $? -eq 1 ]]
   then
      echo "Rebooting..."
      sudo reboot
   fi

   # Check for custom Device setup
   if [ -f custom_setup.sh ]
   then
      source custom_setup.sh
      cd ~
   fi

   # Look for internet connection.
   if ping -q -c 1 -W 1 google.com >/dev/null 2>&1
   then
      # TODO: Skip update check if done recently?
      echo "Updating mycroft-core..."
      cd ~/mycroft-core
      git pull
      cd ~
   fi

   # Launch Mycroft Services ======================
   source ~/mycroft-core/start-mycroft.sh all &

   # check to see if the unit has been registered yet
   IDENTITY_FILE="/home/pi/.mycroft/identity/identity2.json"
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
      sleep 10
      say_to_mycroft "pair my device" >/dev/null 2>&1 &
   else
      echo "Mycroft is currently running in the background, so you can say"
      echo "'Hey Mycroft' to activate it. Try saying 'Hey Mycroft, what time is it'"
      echo "to test the system."
   fi
else
   # running from a SSH session
   echo ""
fi


echo ""
echo "***********************************************************************"
echo "In a few moments you will see the contents of the speech log.  Hit"
echo "Ctrl+C to stop showing the log and return to the command line.  Mycroft"
echo "will continue running in the background for voice interaction."
echo ""
echo "Additional commands you can use from the command line:"
echo "    mycroft-cli-client - command line client, useful for debugging"
echo "    msm                - Mycroft Skills Manager, install new Skills"
echo "    say_to_mycroft     - one-shot commands from the command line"
echo "    speak              - say something to the user"
echo "    test_microphone    - record and playback to test your microphone"
echo "***********************************************************************"
echo ""

sleep 5  # for some reason this delay is needed for the mic to be detected
source ~/mycroft-core/start-mycroft.sh cli
