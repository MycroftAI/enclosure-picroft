# It's Alive!
![Lightning over Plexpod](https://raw.githubusercontent.com/MycroftAI/enclosure-picroft/stretch/lightning-2018-08-01.jpg )

## Picroft - 2019-07-20 Stretch Lightning release

Picroft is an enclosure for a Raspberry Pi 3 or 3B+ connected to a speaker and
microphone, bringing Mycroft to anyone who wants a simple voice interface they
have complete control over.  This is built on top of the official Raspbian
Stretch Lite image.

The entire project is available as a pre-built micro-SD image ready to be
burned and placed into a Raspberry Pi. You can download the pre-built image
here:

 [![Download img](https://github.com/MycroftAI/enclosure-picroft/raw/master/microsd-icon.png "Download img") Picroft Stable 2019-07-20 image](https://mycroft.ai/to/picroft-image)

SHA-256: 6fe5ca091efa65899063793ecb1182c1e529dffb01ceea4b2283e6c75ccf5d10

[![Download img](https://github.com/MycroftAI/enclosure-picroft/raw/master/microsd-icon.png "Download img") Picroft Unstable 2019-09-26 image](https://mycroft.ai/to/picroft-unstable)

SHA-256: 2c1ec01d3e81beb910e5ff7275fb5b21537b58f071d2b10a33675d6597c71011

Optionally you can build it yourself by following the [Recipe for building the image](image_recipe.md)

## Requirements

* **Raspberry Pi 3 or 3B+**
  <br>_Older Raspberry Pi versions do not have sufficient processing power,
  and if they work they will be very slow_
* **Speaker**
  <br>Any analog speaker, or an HDMI monitor with speaker
* **Microphone**
  <br>Tested with: PlayStation Eye; Blue Snowball; Google AIY v1; Seeed Studio
  Mic Array 2.0; Matrix Voice; Logitech Webcam Pro 9000, C525 and C270; CREATIVE VF0790.
* **2.5 Amp or better power supply**
  <br>Don't skimp on this!  It might appear to work, but you'll have weird
  issues with a cheapo supply.
* **MicroSD Card**
  <br>8 GB or larger
* HDMI Monitor and keyboard, only required during setup


## Installation

1) Download and burn the image to the SD card.<br/>See the RaspberryPi.org's
   guide to
   [Installing Operating System Images](https://www.raspberrypi.org/documentation/installation/installing-images/)
   for detailed instructions on how to burn an image to your SD card.
2) Insert the SD card into your Raspberry Pi
3) Connect speaker, microphone, monitor and keyboard
4) Apply power
5) Follow the on-screen prompts to setup Picroft
6) Follow the verbal prompts to pair your device to an account at
   [Mycroft Home](http://home.mycroft.ai/#/device/add)
7) Talk to Mycroft and enjoy!

## Usage

Simply speak to Picroft as you would to any Mycroft.  For example:

    "Hey Mycroft, what time is it?"
    "Mycroft, how tall was Abraham Lincoln?"


## Older Versions
* [Raspbian Jessie version](https://github.com/MycroftAI/enclosure-picroft/tree/master)

## Help and more info
To re-run the setup wizard, use `mycroft-setup-wizard`.
Check out the Picroft wiki [here](https://mycroft.ai/documentation/picroft/).
There's also the general [Documentation](https://mycroft.ai/documentation/).

## Customization
* `audio_setup.sh` configures your specific audio setup.
* `custom_setup.sh` is a stub meant to initialize anything before Mycroft
  starts.  For example, initializing connected devices, or launching services.

## Getting Help

There is an active *Picroft* community within the [Mycroft's Mattermost chat](https://chat.mycroft.ai/community/channels/picroft) which all are welcome to join!

---

### FAQ
##### Q1) Why "Stretch Lightning"?
Because the image is built on Raspbian Stretch, and the lightning seen above
was captured from the roof the night I started this rework.

##### Q2) Can I run this with a the Raspbian desktop GUI?
Sadly, not really.  A Raspberry Pi is powerful, but still not well suited to do
_everything_ at once.  You can add other basic services on top of Picroft, but
the desktop GUI requires too many additional resources and neither Mycroft nor
the GUI end up running well.

##### Q3) Can I run this with anything else?
Depends on what you want to add.  Serving simple webpages or polling devices
periodically is probably fine.  Mining bitcoin won't.

##### Q4) Can I run this on a Pi4?
Not yet.  The current Picroft image is based on Raspbian Stretch Lite, and the
Raspberry Pi 4 requires the Raspbian Buster.  Users have reported success with
a generic Linux install of Mycroft on top of a Raspbian Buster image, and we
will be creating an unstable Buster image very soon.
