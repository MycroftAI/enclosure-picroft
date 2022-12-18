#!/bin/bash
##########################################################################
# audio_setup.sh
##########################################################################
# You can use this script to execute custom actions on startup.  It gets
# called by auto_run.sh.  This file will never be replaced by an update.


# You can check what output devices are available with the command:
# `pactl list sinks short`
#
# The analog headphone jack would be listed as:
# alsa_output.platform-bcm2835_audio.analog-stereo
#
# The Pi's digital audio output will be listed as:
# alsa_output.platform-bcm2835_audio.digital-stereo
#
# Whilst a USB speaker will be listed more explicitly eg:
# alsa_output.usb-SEEED_ReSpeaker_4_Mic_Array__UAC1.0_-00.analog-stereo
#
# You can set one of these as the default PulseAudio device by uncommenting
# one of these lines or adding your own:
# pactl set-default-sink alsa_output.platform-bcm2835_audio.analog-stereo
# pactl set-default-sink alsa_output.platform-bcm2835_audio.digital-stereo
# pactl set-default-sink alsa_output.usb-SEEED_ReSpeaker_4_Mic_Array__UAC1.0_-00.analog-stereo
# pactl set-default-sink $DEVICE_NAME


# You can check what input devices are available with the command:
# `pactl list sources short`
#
# You can set one of these as the default input device by uncommenting
# one of these lines or adding your own:
# pactl set-default-source alsa_output.platform-bcm2835_audio.analog-stereo
# pactl set-default-source alsa_output.platform-bcm2835_audio.digital-stereo
# pactl set-default-source alsa_output.usb-SEEED_ReSpeaker_4_Mic_Array__UAC1.0_-00.analog-stereo
# pactl set-default-source $DEVICE_NAME


# Set the default volume level; 75 is the current default in auto_run.sh
#
# pactl set-sink-volume @DEFAULT_SINK@ 75%
#
# You can set a default volume for specific output devices by using the device
# name in place of "@DEFAULT_SINK@"


# You can make Mycroft say anything you want on startup!
# Try uncommenting one of the following:
# speak "It is so good to be back online!"
# speak "I come in peace"
# speak "I am Mycroft. Take me to your leader!"
