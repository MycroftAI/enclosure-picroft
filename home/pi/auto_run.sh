#!/bin/bash
##########################################################################
# auto_run.sh
#
# Copyright 2018 Mycroft AI Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################

# This script is executed by the .bashrc every time someone logs in to the
# system (including shelling in via SSH).

# DO NOT EDIT THIS SCRIPT!  It may be replaced later by the update process,
# but you can edit and customize the audio_setup.sh and custom_setup.sh
# script.  Use the audio_setup.sh to change audio output configuration and
# default volume; use custom_setup.sh to initialize any other IoT devices.
#

export PATH="$HOME/bin:$HOME/mycroft-core/bin:$PATH"

function network_setup() {
    # silent check at first
    if ping -q -c 1 -W 1 1.1.1.1 >/dev/null 2>&1 ; then
        return 0
    fi

    # Wait for an internet connection -- either the user finished Wifi Setup or
    # plugged in a network cable.
    show_prompt=1
    should_reboot=255
    reset_wlan0=0
    while ! ping -q -c 1 -W 1 1.1.1.1 >/dev/null 2>&1 ; do
        if [ $show_prompt = 1 ]
        then
            echo "Network connection not found, press a key to setup via keyboard"
            echo "or plug in a network cable:"
            echo "  1) Basic wifi with SSID and password"
            echo "  2) Wifi with no password"
            echo "  3) Edit wpa_supplicant.conf directly"
            echo "  4) Force reboot"
            echo "  5) Skip network setup for now"
            echo -n "Choice [1-6]: "
            show_prompt=0
        fi

        # TODO: Options for WPA 2 Ent, etc?"
        # See:  https://github.com/MycroftAI/enclosure-picroft/blob/master/setup_eap_wifi.sh
        # See also:  https://w1.fi/cgit/hostap/plain/wpa_supplicant/wpa_supplicant.conf

        read -N1 -s -t 1 pressed

        case $pressed in
         1)
            echo
            echo -n "Enter a network SSID: "
            read user_ssid
            echo -n "Enter the password: "
            read -s user_pwd
            echo
            echo -n "Enter the password again: "
            read -s user_confirm
            echo

            if [[ "$user_pwd" = "$user_confirm" && "$user_ssid" != "" ]]
            then
                echo "network={" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
                echo "        ssid=\"$user_ssid\"" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
                echo "        psk=\"$user_pwd\"" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
                echo "}" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
                reset_wlan0=1
                break
            else
                show_prompt=1
            fi
            ;;
         2)
            echo
            echo -n "Enter a network SSID: "
            read user_ssid

            if [ ! "$user_ssid" = "" ]
            then
                echo "network={" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
                echo "        ssid=\"$user_ssid\"" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
                echo "        key_mgmt=NONE" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
                echo "}" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
                reset_wlan0=5
                break
            else
                show_prompt=1
            fi
            ;;
         3)
            sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
            reset_wlan0=5
            break
            ;;
         4)
            should_reboot=1
            break
            ;;
         5)
            should_reboot=0
            break;
            ;;
        esac

        if [[ $reset_wlan0 -gt 0 ]]
        then
            if [[ $reset_wlan0 -eq 5 ]]
            then
                echo "Reconfiguring WLAN0..."
                wpa_cli -i wlan0 reconfigure
                show_prompt=1
                sleep 3
            elif [[ $reset_wlan0 -eq 1 ]]
            then
                echo "Failed to connect to network."
                show_prompt=1
            else
                # decrement the counter
                reset_wlan0= expr $reset_wlan0 - 1
            fi

            $reset_wlan0=4
        fi

    done

    if [[ $should_reboot -eq 255 ]]
    then
        # Auto-detected
        echo
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

    echo
    echo "========================================================================="
    echo "HARDWARE SETUP"
    echo "How do you want Mycroft to output audio:"
    echo "  1) Speakers via 3.5mm output (aka 'audio jack' or 'headphone jack')"
    echo "  2) HDMI audio (e.g. a TV or monitor with built-in speakers)"
    echo "  3) USB audio (e.g. a USB soundcard or USB mic/speaker combo)"
    echo "  4) Google AIY Voice HAT and microphone board (Voice Kit v1)"
    echo -n "Choice [1-4]: "
    while true; do
        read -N1 -s key
        case $key in
         1)
            echo "$key - Analog audio"
            # audio out the analog speaker/headphone jack
            sudo amixer cset numid=3 "1" > /dev/null
            echo 'sudo amixer cset numid=3 "1" > /dev/null' >> ~/audio_setup.sh
            break
            ;;
         2)
            echo "$key - HDMI audio"
            # audio out the HDMI port (e.g. TV speakers)
            sudo amixer cset numid=3 "2" > /dev/null
            echo 'sudo amixer cset numid=3 "2"  > /dev/null' >> ~/audio_setup.sh
            break
            ;;
         3)
            echo "$key - USB audio"
            # audio out to the USB soundcard
            sudo amixer cset numid=3 "0" > /dev/null
            echo 'sudo amixer cset numid=3 "0"  > /dev/null' >> ~/audio_setup.sh
            break
            ;;
         4)
            echo "$key - Google AIY Voice HAT and microphone board (Voice Kit v1)"
            # Get AIY drivers
            if [ ! -f /etc/apt/sources.list.d/aiyprojects.list ]; then
            
                echo "deb https://dl.google.com/aiyprojects/deb stable main" | sudo tee -a /etc/apt/sources.list.d/aiyprojects.list
                wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
                    
                sudo apt-get -y update
                sudo apt-get -y upgrade
                # hack to get aiy-io-mcu-firmware to be installed
                sudo mkdir /usr/lib/systemd/system

                sudo apt-get -y install aiy-dkms aiy-io-mcu-firmware aiy-vision-firmware dkms raspberrypi-kernel-headers
                sudo apt-get -y install aiy-dkms aiy-voicebonnet-soundcard-dkms aiy-voicebonnet-routes
                sudo apt-get -y install aiy-python-wheels
                sudo apt-get -y install leds-ktd202x-dkms

                # we need pulseaudio
                sudo apt-get -y install pulseaudio

                # make soundcard recognizable
                sudo sed -i \
                    -e "s/^dtparam=audio=on/#\0/" \
                    -e "s/^#\(dtparam=i2s=on\)/\1/" \
                    /boot/config.txt
                grep -q "dtoverlay=i2s-mmap" /boot/config.txt || \
                sudo sh -c "echo 'dtoverlay=i2s-mmap' >> /boot/config.txt"
                grep -q "dtoverlay=googlevoicehat-soundcard" /boot/config.txt || \
                sudo sh -c "echo 'dtoverlay=googlevoicehat-soundcard' >> /boot/config.txt"
                grep -q "dtparam=i2s=on" /boot/config.txt || \
                sudo sh -c "echo 'dtparam=i2s=on' >> /boot/config.txt"

                # make changes to  mycroft.conf
                sudo sed -i \
                    -e "s/aplay -Dhw:0,0 %1/aplay %1/" \
                    -e "s/mpg123 -a hw:0,0 %1/mpg123 %1/" \
                    /etc/mycroft/mycroft.conf

                # Install asound.conf
                sudo cp AIY-asound.conf /etc/asound.conf

                # rebuild venv
                mycroft-core/dev_setup

                # TODO: reboot needed?
                # YES reboot neded !
                echo "Reboot is neded !"
                break
                #;;
            fi
            
        esac
    done

    lvl=7
    echo
    echo "Let's test and adjust the volume:"
    echo "  1-9) Set volume level (1-quietest, 9=loudest)"
    echo "  T)est"
    echo "  R)eboot (needed if you just installed Google Voice Hat or plugged in a USB speaker)"
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

    echo
    echo "The final step is Microphone configuration:"
    echo "As a voice assistant, Mycroft needs to access a microphone to operate."

    while true; do
        echo "Please ensure your microphone is connected and select from the following"
        echo "list of microphones:"
        echo "  1) PlayStation Eye (USB)"
        echo "  2) Blue Snoball ICE (USB)"
        echo "  3) Google AIY Voice HAT and microphone board (Voice Kit v1)"
        echo "  4) Other (unsupported -- good luck!)"
        echo -n "Choice [1-4]: "
        echo
        while true; do
            read -N1 -s key
            case $key in
             1)
                echo "$key - PS Eye"
                # nothing to do, this is the default
                break
                ;;
             2)
                echo "$key - Blue Snoball"
                # nothing to do, this is the default
                break
                ;;
             3)
                echo "$key - Google AIY Voice Hat"
                break
                ;;
             4)
                echo "$key - Other"
                echo "Other microphone _might_ work, but there are no guarantees."
                echo "We'll run the tests, but you are on your own.  If you have"
                echo "issues, the most likely cause is an incompatible microphone."
                echo "The PS Eye is cheap -- save yourself hassle and just buy one!"
                break
                ;;
            esac
        done

        echo
        echo "Testing microphone..."
        echo "In a few seconds you will see some initialization messages, then a prompt"
        echo "to speak.  Say something like 'testing 1 2 3 4 5 6 7 8 9 10'.  After"
        echo "10 seconds, the sound heard through the microphone will be played back."
        echo
        echo "Press any key to begin the test..."
        sleep 1
        read -N1 -s key

        # Launch mycroft-core audio test
        ./mycroft-core/start-mycroft.sh audiotest

        retry_mic=0
        echo
        echo "Did you hear the yourself in the audio?"
        echo "  1) Yes!"
        echo "  2) No, let's repeat the test."
        echo "  3) No :(   Let's move on and I'll mess with the microphone later."
        echo -n "Choice [1-3]: "
        while true; do
            read -N1 -s key
            case $key in
             [1])
                echo "$key - Yes, good to go"
                break
                ;;
             [2])
                echo "$key - No, trying again"
                echo
                retry_mic=1
                break
                ;;
             [3])
                echo "$key - No, I give up and will use command line only (for now)!"
                break
                ;;
            esac
        done

        if [ $retry_mic -eq 0 ] ; then
            break
        fi
    done

    echo "========================================================================="
    echo "MYCROFT SETUP"
    echo "Mycroft is continuously updated.  For most users it is recommended that"
    echo "you run on the 'master' branch -- which always holds stable builds -- and"
    echo "allow the system to automatically upgrade with the biweekly releases."
    echo "  1) Use the recommendations ('master' / auto-update)"
    echo "  2) I'm a core developer, put me on 'dev' and I'll manage updates"
    echo -n "Choice [1-2]: "
    while true; do
        read -N1 -s key
        case $key in
         1)
            echo "$key - Easy street, 'master' and automatically update"
            echo '{"use_branch":"master", "auto_update": true}' > ~/mycroft-core/.dev_opts.json
            cd ~/mycroft-core
            git checkout masterll
            cd ..
            break
            ;;
         2)
            echo "$key - I know what I'm doing and am a responsible human."
            echo '{"use_branch":"dev", "auto_update": false}' > ~/mycroft-core/.dev_opts.json
            cd ~/mycroft-core
            git checkout dev
            cd ..
            break
            ;;
        esac
    done


    echo "========================================================================="
    echo "SECURITY SETUP:"
    echo "Let's examine a few security settings."
    echo
    echo "By default, Raspbian is configured to not require a password to perform"
    echo "actions as root (e.g. 'sudo ...').  This allows any application on the"
    echo "pi to have full access to the system.  This can make some development"
    echo "tasks easy, but is less secure.  Would you like to remain with this default"
    echo "setup or would you lke to enable standard 'sudo' password behavior?"
    echo "  1) Stick with normal Raspian configuration, no password for 'sudo'"
    echo "  2) Require a password for 'sudo' actions."
    echo -n "Choice [1-2]: "
    require_sudo=0
    while true; do
        read -N1 -s key
        case $key in
         [1])
            echo "$key - No password"
            # nothing to do, this is the default
            require_sudo=0
            break
            ;;
         [2])
            echo "$key - Enabling password protection for 'sudo'"
            require_sudo=1
            break
            ;;
        esac
    done


    echo "Unlike standard Raspbian which has a user 'pi' with a password 'raspberry',"
    echo "the Picroft image uses the following as default username and password:"
    echo "  Default user:      pi"
    echo "  Default password:  mycroft"
    echo "As a network connected device, having a unique password significantly"
    echo "enhances your security and thwarts the majority of hacking attempts."
    echo "We recommend setting a unique password for any device, especially one"
    echo "that is exposed directly to the internet."
    echo " "
    echo "Would you like to enter a new password?"
    echo "  Y)es, prompt me for a new password"
    echo "  N)o, stick with the default password of 'mycroft'"
    echo -n "Choice [Y,N]:"
    while true; do
        read -N1 -s key
        case $key in
        [Yy])
            echo "$key - changing password"
            user_pwd=0
            user_confirm=1
            echo -n "Enter your new password (characters WILL NOT appear): "
            read -s user_pwd
            echo
            echo -n "Enter your new password again: "
            read -s user_confirm
            echo
            if [ "$user_pwd" = "$user_confirm" ]
            then
                # Change 'pi' user password
                echo "pi:$user_pwd" | sudo chpasswd
                break
            else
                echo "Passwords didn't match."
            fi
            ;;
        [Nn])
           echo "$key - Using password 'mycroft'"
           break
           ;;
        esac
    done

    if [ $require_sudo -eq 1 ]
    then
        echo "pi ALL=(ALL) ALL" | sudo tee /etc/sudoers.d/010_pi-nopasswd
    fi

    echo
    echo "========================================================================="
    echo
    echo "That's all, setup is complete!  Now we'll pull down the latest software"
    echo "updates and start Mycroft.  You'll be prompted to pair this device with"
    echo "an account at https://home.mycroft.ai, then you'll be set to enjoy your"
    echo "Picroft!"
    echo
    echo "To rerun this setup, type 'mycroft-setup-wizard' and reboot."
    echo
    echo "Press any key to launch Mycroft..."
    read -N1 -s anykey
}

function speak() {
    ~/mycroft-core/mimic/bin/mimic -t $@
}

######################

echo -e "\e[36m"
echo " ███╗   ███╗██╗   ██╗ ██████╗██████╗  ██████╗ ███████╗████████╗"
echo " ████╗ ████║╚██╗ ██╔╝██╔════╝██╔══██╗██╔═══██╗██╔════╝╚══██╔══╝"
echo " ██╔████╔██║ ╚████╔╝ ██║     ██████╔╝██║   ██║█████╗     ██║   "
echo " ██║╚██╔╝██║  ╚██╔╝  ██║     ██╔══██╗██║   ██║██╔══╝     ██║   "
echo " ██║ ╚═╝ ██║   ██║   ╚██████╗██║  ██║╚██████╔╝██║        ██║   "
echo " ╚═╝     ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝        ╚═╝   "
echo
echo "        _____    _                          __   _   "
echo "       |  __ \  (_)                        / _| | |  "
echo "       | |__) |  _    ___   _ __    ___   | |_  | |_ "
echo "       |  ___/  | |  / __| | '__|  / _ \  |  _| | __|"
echo "       | |      | | | (__  | |    | (_) | | |   | |_ "
echo "       |_|      |_|  \___| |_|     \___/  |_|    \__|"
echo -e "\e[0m"
echo

# Read the current mycroft-core version
source mycroft-core/venv-activate.sh -q
mycroft_core_ver=$(python -c "import mycroft.version; print('mycroft-core: '+mycroft.version.CORE_VERSION_STR)" && echo "steve" | grep -o "mycroft-core:.*")
mycroft_core_branch=$(cd mycroft-core && git branch | grep -o "/* .*")

echo "***********************************************************************"
echo "** Picroft enclosure platform version:" $(<version)
echo "**                       $mycroft_core_ver ( ${mycroft_core_branch/* /} )"
echo "***********************************************************************"
sleep 2  # give user a few moments to notice the version


alias mycroft-setup-wizard="cd ~ && touch first_run && source auto_run.sh"

if [ -f ~/first_run ]
then
    echo
    echo "Welcome to Picroft.  This image is designed to make getting started with"
    echo "Mycroft quick and easy.  Would you like help setting up your system?"
    echo "  Y)es, I'd like the guided setup."
    echo "  N)ope, just get me a command line and get out of my way!"
    echo -n "Choice [Y/N]: "
    while true; do
        read -N1 -s key
        case $key in
         [Nn])
            echo $key
            echo
            echo "Alright, have fun!"
            echo "NOTE: If you decide to use the wizard later, just type 'mycroft-setup-wizard'"
            echo "      and reboot."
            break
            ;;
         [Yy])
            echo $key
            echo
            setup_wizard
            break
            ;;
        esac
    done

   # Delete to flag setup is complete
    rm ~/first_run
fi


if [ "$SSH_CLIENT" == "" ] && [ "$(/usr/bin/tty)" = "/dev/tty1" ];
then
    # running at the local console (e.g. plugged into the HDMI output)

    # Make sure the audio is being output reasonably.  This can be set
    # to match user preference in audio_setup.sh.  DON'T EDIT HERE,
    # the script will likely be overwritten during later updates.
    #
    # Default to analog audio jack at 75% volume
    amixer cset numid=3 "1" > /dev/null
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
    if ping -q -c 1 -W 1 1.1.1.1 >/dev/null 2>&1
    then
        echo "**** Checking for updates to Picroft environment"
        cd /tmp
        wget -N -q https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/stretch/home/pi/version >/dev/null
        if [ $? -eq 0 ]
        then
            if [ ! -f ~/version ] ; then
                echo "unknown" > ~/version
            fi

            cmp /tmp/version ~/version
            if  [ $? -eq 1 ]
            then
                # Versions don't match...update needed
                echo "**** Update found, downloadling new Picroft scripts!"
                speak "Updating Picroft, please hold on."

                # Stop interactive parts of mycroft, as we don't
                # want the user interacting with it while updating.
                sudo service mycroft-skills stop

                wget -N -q https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/stretch/home/pi/update.sh
                if [ $? -eq 0 ]
                then
                    source update.sh
                    cp /tmp/version ~/version

                    # restart
                    echo "Restarting..."
                    speak "Update complete, restarting."
                    sudo reboot now
                else
                    echo "ERROR: Failed to download update script."
                fi
            fi
        fi

        # TODO: Skip update check if done recently?
        echo -n "Checking for mycroft-core updates..."
        cd ~/mycroft-core
        git pull
        cd ~
    fi

    # Launch Mycroft Services ======================
    source ~/mycroft-core/start-mycroft.sh all &
else
    # running in SSH session
    echo
fi

echo
mycroft-help

echo
echo "***********************************************************************"
echo "In a few moments you will see the contents of the speech log.  Hit"
echo "Ctrl+C to stop showing the log and return to the Linux command line."
echo "Mycroft will continue running in the background for voice interaction."
echo

sleep 5  # for some reason this delay is needed for the mic to be detected
"$HOME/mycroft-core/start-mycroft.sh" cli

