#!/bin/bash
##########################################################################
# audio_setup.sh
##########################################################################
# You can use this script to execute custom actions on startup.  It gets
# called by auto_run.sh.  This file will never be replaced by an update.


# Uncomment one of lines to change output audio such as the HDMI port, e.g. the
# connected TV's speakers.  By default audio is output by the headphone jack.
#
# You can check what ALSA output you have with the command `aplay -L`
#
# Below are the assumed output locations for each output type.
# While the Raspberry Pi is a standard board, these have been known to vary by
# system; you can always use `aplay -L` to check
# sudo amixer cset numid=3 "0"  # audio out to the USB soundcard
# sudo amixer cset numid=3 "1"  # audio out the analog speaker/headphone jack
# sudo amixer cset numid=3 "2"  # audio out the HDMI port (e.g. TV speakers)


# Set the default volume level; 75 is the current default in auto_run.sh
#
# amixer set Master 75%


# Any speaker output you want on startup!
# speak "It is so good to be back online!"
# speak "I come in peace"
# speak "I am Mycroft. Take me to your leader!"
