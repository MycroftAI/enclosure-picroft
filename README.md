# Picroft 0.9
The Picroft project is an enclosure for a stock Raspberry Pi connected to a speaker and basic USB microphone.  This is built around a Raspbian Jessie Lite installation.  The entire project is available as a pre-built micro-SD image ready to be burned and placed into a Raspberry Pi.  You can download the pre-built image here:

 [![Download img](https://github.com/MycroftAI/enclosure-picroft/raw/master/microsd-icon.png "Download img") Picroft 0.9 image](https://mycroft.ai/to/picroft-image)

SHA256 checksum for the mark-1_production_20171019_build-10.zip image:
98eccba84c1b923966a4bb71410ad0177a36871370f6b292fc875993fdf60d90

# Requirements

* Raspberry Pi 3 (Older versions do not have sufficient processing power, and if they work they will be very slow)
* MicroSD Card (4 GB or larger)
* Any analog speaker
* USB Microphone.  Tested with CM108-based microphones.

# Installation

[Official Raspberry Pi Image Installation Instuctions](https://www.raspberrypi.org/documentation/installation/installing-images/)

[Etcher](https://etcher.io/) Cross-Platform GUI SD card creator for RPi

### Advanced Installation
- [Windows](https://www.raspberrypi.org/documentation/installation/installing-images/windows.md)
- [OSX/MacOS](https://www.raspberrypi.org/documentation/installation/installing-images/mac.md)
- [Linux](https://www.raspberrypi.org/documentation/installation/installing-images/linux.md)

# Usage

Upon boot, Picroft will search for an Ethernet connection.  If none is found, the Wifi Setup process will begin to get the device connected to any available network.

Once connected, you must pair the device at https://home.mycroft.ai using the code spoken by the device.  You can also read the code on the screen.

After that, you can simply speak to Picroft as you would to any Mycroft implementation.  For example:

  "Hey Mycroft, what time is it?"
  "Mycroft, how tall was Abraham Lincoln?"


# Versions
* [0.9](https://mycroft.ai/to/picroft-image) - Preloaded with 17.08a, auto-upgrading from this repo
* [0.8](https://rebrand.ly/Picroft-0_8) - Connecting to Home backend
* [0.5.1](https://rebrand.ly/Picroft-0_5_1) - Fixed several audio issues with 0.5 image
* 0.5 - Original image, connecting to Cerberus backend

# Help and more info
Check out the project wiki [here](https://github.com/MycroftAI/enclosure-picroft/wiki).  
There's also the general [Documentation](https://docs.mycroft.ai/).

# There are two scripts run on startup
* `audio_setup.sh` configures your specific audio setup.
* `custom_setup.sh` is a stub meant to initialize any other IoT devices or services you might need like a DLNA server or syslog for example.

# Using USB Audio as Output

Typically the USB audio should be connected to hwplug:1,0 but to verify run the following:

`aplay -L`

Find the hwplug output for the device you want to use, take this and update the /etc/mycroft/mycroft.conf file accordingly:

"play_wav_cmdline": "aplay -Dhw:0,0 %1" this line now becomes "play_wav_cmdline": "aplay -Dplughw:1,0 %1"

You can now run ./auto_run.sh to start the program back up and test and ensure the output comes through the USB speakers.

---

There is an active *Picroft* community within the [Mycroft Mattermost Channel](https://chat.mycroft.ai) which are welcome to join!
