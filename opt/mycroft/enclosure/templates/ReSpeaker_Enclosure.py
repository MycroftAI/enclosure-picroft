#!/usr/bin/env python
##########################################################################
# ReSpeaker_Enclosure.py
#
# Copyright 2019, Stephen Penrod
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

# This file defines a custom enclosure for your Picroft using a Seeed ReSpeaker
# Mic Array.  By default it supports:
#   * Animations on the pixel ring on the mic array
#   * A button connected to the GPIO-23 as a Stop button
#   * Reboot and shutdown administrative actions
#
# Feel free to modify this code to your own purposes.  Changes will not be
# overwritten by the update process will not overwrite it.  This code monitors
# the messagebus for system events, listens to GPIOs, and can do just about
# anything you'd like.
#
# Changes to my_enclosure.py will restart the enclosure process automatically
# but be careful -- syntax errors will require manual relaunching or reboot
# after the error is fixed.

from lib.picroft_enclosure import Picroft_Enclosure
from time import sleep

# The pixel_ring code is installed from Github in the home directory
import sys
sys.path.insert(1, '/home/pi/usb_4_mic_array/pixel_ring')
from pixel_ring import pixel_ring

import lib.file_watchdog as watchdog
watchdog.watch(__file__)

##########################################################################

class ReSpeaker_Enclosure(Picroft_Enclosure):

    def __init__(self):
        super().__init__(led_gpio_bcm=None)  # Pixel Ring is used to show state
                                             # instead of a LED on a GPIO

    def indicate_booting(self):
        # Visual indication that system is booting
        pixel_ring.set_brightness(2)
        pixel_ring.spin()

    def indicate_booting_done(self, message):
        # Boot has completed, turn off booting visualization
        pixel_ring.off()

    def indicate_sleeping(self, message):
        # Turn lights orange when asleep
        pixel_ring.set_color(False, 250, 60, 0)
        self.asleep = True

    def indicate_waking(self, message):
        # Restore lights when woken
        pixel_ring.spin()
        sleep(2)
        pixel_ring.off()
        self.asleep = False

    ######################################################################
    # Interaction sequence indicators.  The trypical sequence is:
    # - indicate_listening()
    # - indicate_listening_done()
    # - indicate_thinking()
    # - indicate_talking()
    # - indicate_talking_done()
    # - indicate_thinking_done()
    # There are variations on this, for example an inadvertant recording might never
    # begin a handler sequence.  Or there might be multiple output begin/end pairs
    # within the handler.

    # Illuminate lights when listening
    def indicate_listening(self, message):
        if self.asleep:
            return
        pixel_ring.listen()

    def indicate_listening_done(self, message):
        if self.asleep:
            return
        pixel_ring.off()

    def indicate_thinking(self, message):
        if self.asleep:
            return
        pixel_ring.think()

    def indicate_thinking_done(self, message):
        if self.asleep:
            return
        pixel_ring.off()

    def indicate_talking(self, message):
        if self.asleep:
            return
        pixel_ring.speak()

    def indicate_talking_done(self, message):
        if self.asleep:
            return
        pixel_ring.off()


enc = ReSpeaker_Enclosure()
enc.run()
