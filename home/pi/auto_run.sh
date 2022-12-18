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

if [ "$SSH_CLIENT" = "" ] && [ "$(/usr/bin/tty)" != "/dev/tty1" ]; then
    # Quit immediately when running on a local non-primary terminal,
    # e.g. when you hit Ctrl+Alt+F2 to open the second term session
    return 0
fi

export PATH="$HOME/bin:$HOME/mycroft-core/bin:$PATH"

# Read any saved setup choices
if [ -f ~/.setup_choices ]
then
    audio=$( jq -r ".audio" ~/.setup_choices )
    mic=$( jq -r ".mic" ~/.setup_choices )
    setup_stage=$( jq -r ".setup_stage" ~/.setup_choices )
else
    audio=""
    mic=""
    setup_stage=""
fi

function found_exe() {
    hash "$1" 2>/dev/null
}

if found_exe tput ; then
    GREEN="$(tput setaf 2)"
    BLUE="$(tput setaf 4)"
    CYAN="$(tput setaf 6)"
    YELLOW="$(tput setaf 3)"
    RESET="$(tput sgr0)"
    HIGHLIGHT=${YELLOW}
fi

function save_choices() {
    JSON='{}'
    if [[ "$audio" != ""  && "$audio" != "null" ]] ; then
        JSON=$(echo $JSON | jq --arg audio $audio '. + {audio: $audio}')
    fi
    if [[ "$mic" != "" && "$mic" != "null" ]] ; then
        JSON=$(echo $JSON | jq --arg mic $mic '. + {mic: $mic}')
    fi
    if [[ "$setup_stage" != "" && "$setup_stage" != "null" ]] ; then
        JSON=$(echo $JSON | jq --arg setup_stage $setup_stage '. + {setup_stage: $setup_stage}')
    fi
    echo "$JSON" > ~/.setup_choices
}

function set_volume() {
    # Use PulseAudio to set the volume level

    pactl set-sink-volume @DEFAULT_SINK@ $@
}

function save_volume() {
    # Save PulseAudio volume command to set the default volume level

    echo "pactl set-sink-volume @DEFAULT_SINK@ $@" >> ~/audio_setup.sh
}

function network_setup() {
    # silent check at first
    if ping -q -c 1 -W 1 1.1.1.1 >/dev/null 2>&1 ; then
        return 0
    fi

    # Wait for an internet connection -- either the user finished Wifi Setup or
    # plugged in a network cable.
    show_prompt=1
    should_reboot=255
    verify_wifi_countdown=0

    while ! ping -q -c 1 -W 1 1.1.1.1 >/dev/null 2>&1 ; do  # check for network connection
        if [ $show_prompt = 1 ]
        then
            echo "Network connection not found, press a key to setup via keyboard"
            echo "or plug in a network cable:"
            echo "  1) Basic wifi with SSID and password"
            echo "  2) Wifi with no password"
            echo "  3) Edit wpa_supplicant.conf directly"
            echo "  4) Force reboot"
            echo "  5) Skip network setup for now"
            echo -n "${HIGHLIGHT}Choice [1-6]:${RESET} "
            show_prompt=0
        fi

        # TODO: Options for WPA 2 Ent, etc?"
        # See:  https://github.com/MycroftAI/enclosure-picroft/blob/master/setup_eap_wifi.sh
        # See also:  https://w1.fi/cgit/hostap/plain/wpa_supplicant/wpa_supplicant.conf

        read -N1 -s -t 1 pressed  # wait for keypress or one second timeout
        case $pressed in
         1)
            echo
            echo -n "${HIGHLIGHT}Enter a network SSID:${RESET} "
            read user_ssid
            echo -n "${HIGHLIGHT}Enter the password:{RESET} "
            read -s user_pwd
            echo
            echo -n "${HIGHLIGHT}Enter the password again:{RESET} "
            read -s user_confirm
            echo

            if [[ "$user_pwd" = "$user_confirm" && "$user_ssid" != "" ]]
            then
                echo "network={" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
                echo "        ssid=\"$user_ssid\"" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
                echo "        psk=\"$user_pwd\"" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
                echo "}" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
                verify_wifi_countdown=20
            else
                show_prompt=1
            fi
            ;;
         2)
            echo
            echo -n "${HIGHLIGHT}Enter a network SSID:${RESET} "
            read user_ssid

            if [ ! "$user_ssid" = "" ]
            then
                echo "network={" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
                echo "        ssid=\"$user_ssid\"" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
                echo "        key_mgmt=NONE" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
                echo "}" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
                verify_wifi_countdown=20
            else
                show_prompt=1
            fi
            ;;
         3)
            sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
            verify_wifi_countdown=20
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

        if [[ $verify_wifi_countdown -gt 0 ]]
        then
            if [[ $verify_wifi_countdown -eq 20 ]]
            then
                echo -n "Reconfiguring WLAN0..."
                wpa_cli -i wlan0 reconfigure
                echo -n "Detecting network connection."
                sleep 1
            elif [[ $verify_wifi_countdown -eq 1 ]]
            then
                # Wireless network connection didn't come up within 20 seconds
                echo "Failed to connect to network, please try again."
                show_prompt=1
            else
                echo -n "."
            fi

            # decrement the counter every second
            ((verify_wifi_countdown -= 1))
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

function update_software() {
    # Look for internet connection.
    if ping -q -c 1 -W 1 1.1.1.1 >/dev/null 2>&1
    then
        echo "**** Checking for updates to Picroft environment"
        echo "This might take a few minutes, please be patient..."

        cd /tmp
        wget -N -q https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/buster/home/pi/version >/dev/null
        if [ $? -eq 0 ]
        then
            if [ ! -f ~/version ] ; then
                echo "unknown" > ~/version
            fi

            cmp /tmp/version ~/version
            if  [ $? -eq 1 ]
            then
                # Versions don't match...update needed
                echo "**** Update found, downloading new Picroft scripts!"
                speak "Updating Picroft, please hold on."

                wget -N -q https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/buster/home/pi/update.sh
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

        git fetch
        if [ $(git rev-parse HEAD) != $(git rev-parse @{u}) ] ; then
            git pull
            sudo apt-get -o Acquire::ForceIPv4=true update -y
            bash dev_setup.sh
        fi
        cd ~
    fi
}

function setup_wizard() {

    # Handle internet connection
    network_setup
    if [[ $? -eq 1 ]]
    then
        echo "Rebooting..."
        setup_stage="net_reboot"
        save_choices
        sudo reboot
    fi
    if [ "$setup_stage" = "net_reboot" ] ; then
        setup_stage=""
        save_choices
    fi


    # Check for/download new software (including mycroft-core dependencies, while we are at it).
    echo '{"use_branch":"master", "auto_update": true}' > ~/mycroft-core/.dev_opts.json
    update_software

    # installs Pulseaudio if not already installed
    if [ $(dpkg-query -W -f='${Status}' pulseaudio 2>/dev/null | grep -c "ok installed") -eq 0 ];
    then
        sudo apt-get install pulseaudio -y
    fi

    if [ -z "$audio" ] ; then
        echo
        echo "========================================================================="
        echo "HARDWARE SETUP"
        echo "How do you want Mycroft to output audio:"
        echo "  1) Speakers via 3.5mm output (aka 'audio jack' or 'headphone jack')"
        echo "  2) HDMI audio (e.g. a TV or monitor with built-in speakers)"
        echo "  3) USB audio (e.g. a USB soundcard or USB mic/speaker combo)"
        echo "  4) Google AIY Voice HAT and microphone board (Voice Kit v1)"
        echo "  5) ReSpeaker Mic Array v2.0 (speaker plugged in to Mic board)"
        echo -n "${HIGHLIGHT}Choice [1-5]:${RESET} "
        while true; do
            read -N1 -s key
            case $key in
             1)
                echo "$key - Analog audio"
                # audio out the analog speaker/headphone jack
                pactl set-default-sink alsa_output.platform-bcm2835_audio.analog-stereo
                echo 'pactl set-default-sink alsa_output.platform-bcm2835_audio.analog-stereo' >> ~/audio_setup.sh
                audio="analog_audio"
                break
                ;;
             2)
                echo "$key - HDMI audio"
                # audio out the HDMI port (e.g. TV speakers)
                pactl set-default-sink alsa_output.platform-bcm2835_audio.digital-stereo
                echo 'pactl set-default-sink alsa_output.platform-bcm2835_audio.digital-stereo' >> ~/audio_setup.sh
                audio="hdmi_audio"
                break
                ;;
             3)
                echo "$key - USB audio"
                # audio out to the USB soundcard
                echo "Select your output device"
                pactl list sinks short | awk '{printf("  %d) %s\n", NR, $2)}'
                echo -n "${HIGHLIGHT}Choice:${RESET} "
                read -N1 -s card_num
                card_name=$(pactl list sinks short | awk '{print$2}' | sed -n ${card_num}p)
                pactl set-default-sink ${card_name}
                echo "pactl set-default-sink ${card_name}" >> ~/audio_setup.sh
                audio="usb_audio"
                break
                ;;
             4)
                echo "$key - Google AIY Voice HAT and microphone board (Voice Kit v1)"
                setup_stage="aiy_setup"
                save_choices

                # Get AIY drivers
                echo "deb https://packages.cloud.google.com/apt aiyprojects-stable main" | sudo tee /etc/apt/sources.list.d/aiyprojects.list
                wget -q -O - https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

                sudo apt-get  -o Acquire::ForceIPv4=true update
                # hack to get aiy-io-mcu-firmware to be installed
                sudo mkdir /usr/lib/systemd/system

                sudo apt-get -y install aiy-dkms aiy-io-mcu-firmware aiy-vision-firmware dkms raspberrypi-kernel-headers
                sudo apt-get -y install aiy-dkms aiy-voicebonnet-soundcard-dkms
                # At this time, 12/17/2018, installing aiy-python-wheels breaks the install
                # https://community.mycroft.ai/t/setting-up-aiy-python-wheels-protobuf-not-supported-on-armv6-1/5130/2
                # sudo apt-get install -y aiy-python-wheels
                sudo apt-get -y install leds-ktd202x-dkms

                # make soundcard recognizable
                sudo sed -i \
                    -e "s/^dtparam=audio=on/#\0/" \
                    -e "s/^#\(dtparam=i2s=on\)/\1/" \
                    /boot/config.txt
                grep -q -F "dtoverlay=i2s-mmap" /boot/config.txt || sudo echo "dtoverlay=i2s-mmap" | sudo tee -a /boot/config.txt
                grep -q -F "dtoverlay=googlevoicehat-soundcard" /boot/config.txt || sudo echo "dtoverlay=googlevoicehat-soundcard" | sudo tee -a /boot/config.txt

                # fix bug that where audio gets clipped by PulseAudio
                # See: https://github.com/google/aiyprojects-raspbian/issues/297
                sudo sed -i -e "s/^load-module module-suspend-on-idle/#load-module module-suspend-on-idle/" /etc/pulse/default.pa

                # Install asound.conf
                sudo cp AIY-asound.conf /etc/asound.conf

                # rebuild venv
                bash mycroft-core/dev_setup.sh

                echo "Reboot is required, restarting in 5 seconds..."
                audio="google_aiy"
                setup_stage="aiy_reboot"
                save_choices
                sleep 5
                sudo reboot
                ;;
             5)
                echo "$key - Seeed Mic Array v2.0"

                # TODO: Can look for 2886:0018 with lsusb to verify mic is plugged in.

                # Flash latest Seeed firmware
                echo "Downloading and flashing latest firmware from Seeed..."
                sudo /home/pi/mycroft-core/.venv/bin/pip install pyusb click
                git clone https://github.com/respeaker/usb_4_mic_array.git
                cd usb_4_mic_array
                sudo /home/pi/mycroft-core/.venv/bin/python dfu.py --download 1_channel_firmware.bin
                cd ..

                # Configure PulseAudio to use Seeed device
                pactl set-default-source alsa_input.usb-SEEED_ReSpeaker_4_Mic_Array__UAC1.0_-00.analog-mono
                pactl set-default-sink alsa_output.usb-SEEED_ReSpeaker_4_Mic_Array__UAC1.0_-00.analog-stereo
                echo 'pactl set-default-source alsa_input.usb-SEEED_ReSpeaker_4_Mic_Array__UAC1.0_-00.analog-mono' >> ~/audio_setup.sh
                echo 'pactl set-default-sink alsa_output.usb-SEEED_ReSpeaker_4_Mic_Array__UAC1.0_-00.analog-stereo' >> ~/audio_setup.sh

                audio="seed_mic_array_20"
                break
                ;;
            esac
        done
    fi
    if [ "$setup_stage" = "aiy_reboot" ] ; then
        setup_stage=""
    fi

    save_choices

    lvl=7
    echo
    echo "Let's test and adjust the volume:"
    if [ $audio = "seed_mic_array_20" ] ; then
        lvl=" "
    else
        echo "  1-9) Set volume level (1-quietest, 9=loudest)"
    fi
    echo "  T)est"
    echo "  R)eboot (needed if you just plugged in a USB speaker)"
    echo "  D)one!"
    while true; do
        if [ $audio = "seed_mic_array_20" ] ; then
            # Unable to adjust volume via the Seeed, it must be at line level
            # and controlled via an external mechanism.
            echo -n -e "\r${HIGHLIGHT}[T/D/R]:${RESET} ${lvl}          \b\b\b\b\b\b\b\b\b\b"
        else
            echo -n -e "\r${HIGHLIGHT}Level [1-9/T/D/R]:${RESET} ${lvl}          \b\b\b\b\b\b\b\b\b\b"
        fi
        read -N1 -s key
        case $key in
         [1-9])
            lvl=$key
            # Set volume between 19% and 99%.  Lazily not allowing 100% :)
            set_volume "${lvl}9%"
            echo -e -n "\b$lvl PLAYING"
            speak "Test"
            ;;
         [Rr])
            echo "Rebooting..."
            sudo reboot
            ;;
         [Tt])
            set_volume "${lvl}9%"
            echo -e -n "\b$lvl PLAYING"
            speak "Test"
            ;;
         [Dd])
            echo " - Saving"
            break
            ;;
      esac
    done

    if [ "$lvl" != " " ] ; then
        save_volume "${lvl}9%"
    fi

    echo
    echo "The final step is Microphone configuration:"
    echo "As a voice assistant, Mycroft needs to access a microphone to operate."

    while true; do
        if [ "$audio" = "seed_mic_array_20" ] ; then
            echo "Previously you chose a Seeed Mic Array 2.0 for audio output,"
            echo " so we will use that mic."
            mic="seed_mic_array_20"
        elif  [ "$audio" = "google_aiy" ] ; then
            # Google AIY includes both speaker and mic array
            echo "Using Google AIY v1 mic array."
            mic="google_aiy"
        else
            echo "Please ensure your microphone is connected and select from the following"
            echo "list of microphones:"
            echo "  1) PlayStation Eye (USB)"
            echo "  2) Blue Snoball ICE (USB)"
            echo "  3) Matrix Voice HAT."
            echo "  4) Other USB microphone (unsupported -- good luck!)"
            echo -n "${HIGHLIGHT}Choice [1-4]:${RESET} "
            while true; do
                read -N1 -s key
                case $key in
                1)
                    echo "$key - PS Eye"
                    # nothing to do, this is the default
                    mic="ps_eye"
                    break
                    ;;
                2)
                    echo "$key - Blue Snoball"
                    # nothing to do, this is the default
                    mic="blue_snoball"
                    break
                    ;;
                3)
                    echo "$key - Matrix Voice Hat"
                    echo "The Matrix Voice Hat setup will run at the end of the setup"
                    echo "wizard, as it requires several reboots."

                    touch ~/.setup_matrix  # flag to run Matrix install at the end
                    skip_mic_test=true
                    skip_last_prompt=true
                    mic="matrix_voice"
                    break
                    ;;
                4)
                    echo "$key - Other"
                    echo "Other microphones _might_ work, but there are no guarantees."
                    echo "We'll run the tests, but you are on your own.  If you have"
                    echo "issues, the most likely cause is an incompatible microphone."
                    echo "The PS Eye is cheap -- save yourself hassle and just buy one!"
                    echo ""
                    echo "Select your input device"
                    pactl list sources short | awk '{printf("  %d) %s\n", NR, $2)}'
                    echo -n "${HIGHLIGHT}Choice:${RESET} "
                    read -N1 -s card_num
                    card_name=$(pactl list sources short | awk '{print$2}' | sed -n ${card_num}p)
                    pactl set-default-source ${card_name}
                    echo "pactl set-default-source ${card_name}" >> ~/audio_setup.sh
                    mic="other"
                    break
                    ;;
                esac
            done
        fi

        if [ "$skip_mic_test" != true ]; then
            echo
            echo "Testing microphone..."
            echo "When prompted, say something like 'testing 1 2 3 4 5 6 7 8 9 10'."
            echo "After 10 seconds, the sound heard through the microphone play back"
            echo "for microphone verification."
            echo
            echo "${HIGHLIGHT}Press any key to begin the test...${RESET}"
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
            echo -n "${HIGHLIGHT}Choice [1-3]:${RESET} "
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

        else
            break
        fi
    done

    save_choices

    echo "========================================================================="
    echo "MYCROFT SETUP"
    echo "Mycroft is continuously updated.  For most users it is recommended that"
    echo "you run on the 'master' branch -- which always holds stable builds -- and"
    echo "allow the system to automatically upgrade with the biweekly releases."
    echo "  1) Use the recommendations ('master' / auto-update)"
    echo "  2) I'm a core developer, put me on 'dev' and I'll manage updates"
    echo -n "${HIGHLIGHT}Choice [1-2]:${RESET} "
    while true; do
        read -N1 -s key
        case $key in
         1)
            echo "$key - Easy street, 'master' and automatically update"
            echo '{"use_branch":"master", "auto_update": true}' > ~/mycroft-core/.dev_opts.json
            cd ~/mycroft-core
            git checkout master
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
    echo "setup or would you like to enable standard 'sudo' password behavior?"
    echo "  1) Stick with normal Raspian configuration, no password for 'sudo'"
    echo "  2) Require a password for 'sudo' actions."
    echo -n "${HIGHLIGHT}Choice [1-2]:${RESET} "
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


    echo
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
    echo -n "${HIGHLIGHT}Choice [Y,N]:${RESET}"
    while true; do
        read -N1 -s key
        case $key in
        [Yy])
            echo "$key - changing password"
            user_pwd=0
            user_confirm=1
            echo -n "${HIGHLIGHT}Enter your new password (characters WILL NOT appear):${RESET} "
            read -s user_pwd
            echo
            echo -n "${HIGHLIGHT}Enter your new password again:${RESET} "
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

    if [ "$skip_last_prompt" != true ]; then
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
        echo "${HIGHLIGHT}Press any key to launch Mycroft...${RESET}"
        read -N1 -s anykey
    fi
}

function speak() {
    # Generate TTS audio using Mimic 1
    ~/mycroft-core/mimic/bin/mimic -t $@
}

######################

# this will regenerate new ssh keys on boot
# if keys don't exist. This is needed because
# ./bin/mycroft-wipe will delete old keys as
# a security measures
if ! ls /etc/ssh/ssh_host_* 1> /dev/null 2>&1; then
    echo "Generating fresh ssh host keys"
    sudo dpkg-reconfigure openssh-server
    sudo systemctl restart ssh
    echo "New ssh host keys were created. this requires a reboot"
    sleep 2
    sudo reboot
fi

echo -e "${CYAN}"
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
echo -e "${RESET}"
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

if [ -f ~/first_run ]
then
    $(bash "$HOME/mycroft-core/stop-mycroft.sh" all > /dev/null)

    if [ -z "$setup_stage" ] ; then
        echo
        echo "Welcome to Picroft.  This image is designed to make getting started with"
        echo "Mycroft quick and easy.  Would you like help setting up your system?"
        echo "  Y)es, I'd like the guided setup."
        echo "  N)ope, just get me a command line and get out of my way!"
        
        # Something in the boot sequence is sending a CR to the screen, so wait
        # briefly for it to be sent for purely cosmetic purposes.
        sleep 1

        echo -n "${HIGHLIGHT}Choice [Y/N]:${RESET} "
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
                initial_setup=true
                setup_wizard
                break
                ;;
            esac
        done
    else
        echo "Continuing setup..."
        echo
        initial_setup=true
        setup_wizard
    fi

   # Delete to flag setup is complete
    rm ~/first_run
fi

# Special Matrix Voice Hat setup (multiple reboots required)
if [ -f ~/.setup_matrix ]
then
    initial_setup=true
    if [ ! -f matrix_setup_state.txt ]
    then
        echo ""
        echo "========================================================================="
        echo "Installing drivers for Matrix Voice Hat.  This process is automatic, but "
        echo "requires several reboots.  Thanks for your patience!"
        echo
        sleep 2
    else
        echo "Continuing setup of Matrix Voice HAT"
    fi

    if [ ! -f matrix_setup_state.txt ]
    then
        echo "Adding Matrix repo and installing packages..."
        # add repo
        curl https://apt.matrix.one/doc/apt-key.gpg | sudo apt-key add -
        echo "deb https://apt.matrix.one/raspbian $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/matrixlabs.list
        sudo update-ca-certificates
        sudo apt-get -o Acquire::ForceIPv4=true update -y
        sudo apt-get -o Acquire::ForceIPv4=true upgrade -y

        echo "Rebooting to apply kernel updates..."
        echo "stage-1" > matrix_setup_state.txt
        sleep 2
        sudo reboot
    else
        matrix_setup_state=$( cat matrix_setup_state.txt)
    fi

    if [ $matrix_setup_state = "stage-1" ]
    then
        echo "Installing matrixio-kernel-modules..."
        sudo apt install matrixio-kernel-modules -y

        echo "Rebooting to apply audio subsystem changes..."
        echo "stage-2" > matrix_setup_state.txt
        sleep 2
        sudo reboot
    fi

    if [ $matrix_setup_state = "stage-2" ]
    then
        echo "Setting Matrix as standard microphone..."
        echo "========================================================================="
        pactl list sources short
        sleep 5
        pulseaudio -k
        pactl set-default-source 2
        pulseaudio --start
        save_volume 75%
        sleep 2

        mycroft-mic-test

        read -p "${HIGHLIGHT}You should have heard the recording playback. Press enter to continue.${RESET}"

        echo "========================================================================="
        echo "Updating the Python virtual environment"
        bash mycroft-core/dev_setup.sh

        echo "stage-3" > matrix_setup_state.txt
        echo "Your Matrix microphone is now setup! One more reboot to start Mycroft..."
        sudo reboot
    fi

    rm ~/matrix_setup_state.txt
    rm ~/.setup_matrix
fi

if [ "$SSH_CLIENT" = "" ] && [ "$(/usr/bin/tty)" = "/dev/tty1" ];
then
    # running at the local console (e.g. plugged into the HDMI output)

    # Make sure the audio is being output reasonably.  This can be set
    # to match user preference in audio_setup.sh.  DON'T EDIT HERE,
    # the script will likely be overwritten during later updates.
    #
    # Default to analog audio jack at 75% volume
    pactl set-default-sink alsa_output.platform-bcm2835_audio.analog-stereo
    set_volume 75%

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

    # Auto-update to latest version of Picroft scripts and mycroft-core
    update_software
    
    # Launch Mycroft Services ======================
    bash "$HOME/mycroft-core/start-mycroft.sh" all

    # Display success/welcome message for user
    echo
    echo
    mycroft-help
    echo
    
    if [ "$initial_setup" = true ]; then    
        echo "Mycroft is completing startup, ensuring all of the latest versions"
        echo "of skills are installed.  Within a few minutes you will be prompted" 
        echo "to pair this device with the required online services at:"
        echo "https://home.mycroft.ai"
        echo "where you can enter the pairing code."
        sleep 5
        read -p "${HIGHLIGHT}Press enter to launch the Mycroft CLI client.${RESET}"
        "$HOME/mycroft-core/start-mycroft.sh" cli
    else
        echo "Mycroft is now starting in the background."
        echo "To show the Mycroft command line interface type:  mycroft-cli-client"
    fi

else
    # running in SSH session, auto-launch the CLI
    echo
    mycroft-help
    echo
    echo "***********************************************************************"
    echo "In a few moments you will see the Mycroft CLI (command line interface)."
    echo "Hit Ctrl+C to return to the Linux command line.  You can launch the CLI"
    echo "again by entering:  mycroft-cli-client"
    echo
    sleep 2
    "$HOME/mycroft-core/start-mycroft.sh" cli
fi
