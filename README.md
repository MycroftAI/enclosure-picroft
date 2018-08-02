# Welcome

## Picroft - 2018-08-01 Stretch Lightning release

The Picroft project is an enclosure for a stock Raspberry Pi connected to a speaker and basic USB microphone.  This is built around a Raspbian Jessie Lite installation.  The entire project is available as a pre-built micro-SD image ready to be burned and placed into a Raspberry Pi.  You can download the pre-built image here:

 [![Download img](https://github.com/MycroftAI/enclosure-picroft/raw/master/microsd-icon.png "Download img") Picroft 2018-3-14 image](https://mycroft.ai/to/picroft-unstable)
 
SHA256 checksum for the `raspbian-stretch_Picroft_2018-08-01_preview.zip` image:
```TODO```

## Requirements

* Raspberry Pi 3 or 3B+
  <br>_Older Raspberry Pi versions do not have sufficient processing power, and if they work they will be very slow_
* MicroSD Card (8 GB or larger)
* HDMI Monitor and Keyboard
  <br>Only required during setup
* Speaker.
  <br>Any analog speaker, or an HDMI monitor with speaker
* USB Microphone.
  <br>Tested with: PlayStation Eye and CM108-based microphones.


## Installation

1) Download and burn the image to the SD card (see below)
2) Insert the SD card into your Raspberry Pi
3) Connect speaker, microphone, and monitor
4) Apply power
5) Follow the on-screen prompts to setup Picroft
6) Follow the verbal prompts to pair your device to an account at [Mycroft Home](http://home.mycroft.ai/#/device/add)
7) Talk to Mycroft and enjoy!

See the RaspberryPi.org's [Installing Operating System Images](https://www.raspberrypi.org/documentation/installation/installing-images/) for detailed instructions.

## Usage

Simply speak to Picroft as you would to any Mycroft implementation.  For example:

    "Hey Mycroft, what time is it?"
    "Mycroft, how tall was Abraham Lincoln?"


## Old Versions
* [Raspbian Jessie version](https://github.com/MycroftAI/enclosure-picroft/tree/master)

## Help and more info
Check out the project wiki [here](https://github.com/MycroftAI/enclosure-picroft/wiki).  
There's also the general [Documentation](https://docs.mycroft.ai/).

## Customization
* `audio_setup.sh` configures your specific audio setup.
* `custom_setup.sh` is a stub meant to initialize anything before Mycroft starts.  For example, initializing connected devices, or launching services.

## Getting Help

There is an active *Picroft* community within the [Mycroft's Mattermost chat](https://chat.mycroft.ai/community/channels/picroft) which are welcome to join!

---

See also: [Recipe for building the image](image_recipe.md)



