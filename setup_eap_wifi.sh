#!/usr/bin/env bash
# This script sets up WPA 2 Enterprise with PEAP by asking for your user id and pw and then hashes the pw and updates the wpa_supplicant file.
# Author - btotharye


# WPA Supplicant File Location
CONFIG_FILE=/etc/wpa_supplicant/wpa_supplicant.conf

#Gather Name of Wireless SSID
echo What is your Wireless SSID you are trying to add?
read ssid_network

#Gather Userid for PEAP Wifi
echo What is your userid for your wifi?
read username

#Gather PW then hash it for file
echo What is your password for your userid?
read -s -p "Password: " password

#Stripping the (stdin)= part of hash
hash_pw=$(echo -n $password| iconv -t utf16le | openssl md4)
hash_pw_updated=$(echo -e $hash_pw | sed -r 's/^.{9}//')

#Setup Config in Supplicant File
echo -e "network={\nssid="$ssid_network"\npriority=1\nproto=RSN\nkey_mgmt=WPA-EAP\npairwise=CCMP\nauth_alg=OPEN\neap=PEAP\nidentity=$username\npassword=hash:$hash_pw_updated\nphase1="peaplabel=0"\nphase2="auth=MSCHAPV2"}" >> $CONFIG_FILE && echo "SSID $ssid_network has been setup successfully."
