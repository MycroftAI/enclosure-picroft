# Recipe for creating the Picroft IMG

These are the steps followed to create the base image for Picroft on Raspbian Stretch.  This was performed on a Raspberry Pi 3B+

NOTE: At startup Picroft will automatically update itself to the latest version of released software, scripts and Skills.


### Start with the official Raspbian Image
* Download and burn [Raspbian Stretch Lite](https://downloads.raspberrypi.org/raspbian_lite_latest).
  <br>_Last used 2018-06-27 version_
* Install into Raspberry Pi and boot

### General configuration
  - ```sudo raspi-config```
  - 1 Change User Password
      - Enter and verify ```mycroft```
  - 2 Network Options
      - N1 Hostname
        - Enter ```picroft```
      - N3 Network interface names
        - pick *Yes*
  - 3 Boot Options
      - B2 Wait for network
        - pick *No*
  - 4 Localization Options
      - I3 Change Keyboard Layout
          - Pick *Generic 104-key PC*
          - Pick *Other*
          - Pick *English (US)*
          - Pick *English (US)*
          - Pick *The default for the keyboard layout*
          - Pick *No compose key*
      - I4 Change Wi-fi Country
          - Pick *United States*
  - 5 Interfacing Options
      - P2 SSH
          - Pick *Yes*

### Set the device to not use locale settings provided by ssh
* ```sudo nano /etc/ssh/sshd_config``` and comment out the line (prefix with '#')
  ```
  AcceptEnv LANG LC_*
  ```

### Install Picroft scripts
* cd ~
* wget -N https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/feature/common-commands/home/pi/update.sh
* bash update.sh

##### Enable Autologin as the 'pi' user

* ```sudo nano /etc/systemd/system/getty@tty1.service.d/autologin.conf```

* Enter:
```
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I     38400 linux
```

* ```sudo systemctl enable getty@tty1.service```

##### Create RAM disk and point to it
  - ```sudo nano /etc/fstab```
    - Add: ```tmpfs /ramdisk tmpfs rw,nodev,nosuid,size=20M 0 0```
   

##### Environment setup (part of update.sh)

* ```sudo mkdir /etc/mycroft```
* ```sudo nano /etc/mycroft/mycroft.conf```
* mkdir ~/bin

##### Customize .bashrc for startup
* ```nano ~/.bashrc```
   uncomment *#alias ll='ls -l'* near the bottom of the file
   at the bottom add:
   ```
   #####################################
   # This initializes Mycroft
   #####################################
   source ~/auto_run.sh
   ```

##### Install git and mycroft-core
* ```sudo apt-get install git```
* ```git clone https://github.com/MycroftAI/mycroft-core.git```
* ```cd mycroft-core```
* ```git checkout master```
* ```bash dev_setup.sh```

(Wait an hour on a RPi3B+)

## Final steps
* Run ```. ~/bin/mycroft-wipe```
* Remove the SD card
* Create an IMG file named "raspbian-stretch_Picroft_YYYY-MM-DD.img" (optionally include an "_release-suffix.img")
* Compress the IMG using Pishrink.sh
* Upload and adjust redirect link from https://mycroft.ai/picroft-image or https://mycroft.ai/picroft-unstable


