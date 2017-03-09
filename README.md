# Picroft 0.8
The Picroft project is an enclosure for a stock Raspberry Pi connected to a speaker and basic USB microphone.  This is built around a Raspbian Jessie Lite installation.  The entire project is available as a pre-built micro-SD image ready to be burned and placed into a Raspberry Pi.  You can download the pre-built image here:


 [![Download img](https://github.com/MycroftAI/enclosure-picroft/raw/master/microsd-icon.png "Download img") Picroft 0.8 image](https://rebrand.ly/Picroft-0_8)
 

SHA256 checksum for the PiCroft_v0.8b_Raspian_JessieLite_2017-01-26.zip image:
ce316e13f53c261ab22a6856c397170d9dc3dd3bf4c3a5b49e10dcf668ed2c11


# Requirements

* Raspberry Pi 3
* MicroSD Card (4 GB or larger)
* Any analog speaker
* USB Microphone.  Tested with CM108-based microphones.

# Usage

Upon boot, Picroft will search for open wifi networks or an Ethernet connection.  If neither is found, the Wifi Setup process will begin to get the device connected to any available network.

Once connected, you must pair the device at https://home.mycroft.ai using the code spoken by the device.  You can also read the code on the screen.

After that, you can simply speak to Picroft as you would to any Mycroft implementation.  For example:

  "Hey Mycroft, what time is it?"
  "Mycroft, how tall was Abraham Lincoln?"

# Versions
* [0.8](https://rebrand.ly/Picroft-0_8) - Connecting to Home backend
* [0.5.1](https://rebrand.ly/Picroft-0_5_1) - Fixed several audio issues with 0.5 image
* 0.5 - Original image, connecting to Cerberus backend


