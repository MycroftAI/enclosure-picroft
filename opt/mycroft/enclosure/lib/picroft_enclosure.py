#!/usr/bin/env python
##########################################################################
# picroft_enclosure.py
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

# This file defines the base enclosure for your Picroft.  By default
# it supports:
#   * A button connected to the GPIO-23 (and ground) as a "Stop"
#   * A LED connected to the GPIO-21 as an activity indicator
#   * Reboot and shutdown administrative actions
#
# Customizations should be built on top of this.  See the ../templates
# folder for examles, and my_enclosure.py which the setup wizard
# creates for your own special behavior.

from mycroft.client.enclosure.generic import EnclosureGeneric
from mycroft.messagebus.message import Message
from mycroft.util import create_signal
from time import sleep
import os
import sys

from .gpio_button import GPIO_Button
from .gpio_led import GPIO_LED

##########################################################################

class Picroft_Enclosure(EnclosureGeneric):

    def __init__(self, button_gpio_bcm=23, led_gpio_bcm=21):
        super().__init__()

        # Administrative messages
        self.bus.on("system.shutdown", self.on_shutdown)
        self.bus.on("system.reboot", self.on_reboot)
        self.bus.on("system.update", self.on_software_update)

        # Interaction feedback
        self.bus.on("recognizer_loop:wakeword", self.indicate_listening)
        self.bus.on("recognizer_loop:record_begin", self.indicate_listening)
        self.bus.on("recognizer_loop:record_end", self.indicate_listening_done)

        self.bus.on("recognizer_loop:sleep", self.indicate_sleeping)
        self.bus.on("mycroft.awoken", self.indicate_waking)

        self.bus.on("recognizer_loop:audio_output_start", self.indicate_talking)
        self.bus.on("recognizer_loop:audio_output_end", self.indicate_talking_done)
        self.bus.on("mycroft.skill.handler.start", self.indicate_thinking)
        self.bus.on("mycroft.skill.handler.complete", self.indicate_thinking_done)

        # Visual indication that system is booting
        self.bus.on("mycroft.skills.initialized", self.on_ready)

        # Setup to support a button on a GPIO -- default is GPIO23
        if button_gpio_bcm:
            self.button = GPIO_Button(GPIO_BCM=button_gpio_bcm,
                                    on_press=self.on_button_pressed,
                                    on_double_press=self.on_button_double_press,
                                    on_release=self.on_button_released,
                                    on_hold=self.on_button_held)

        # Indicate activity using a LED on selected GPIO
        if led_gpio_bcm:
            self.indicator = GPIO_LED(led_gpio_bcm)  # Feedback LED light
        else:
            self.indicator = None

        self.asleep = False

        self.bus.on("mycroft.skills.initialized", self.indicate_booting_done)
        self.indicate_booting()

    def indicate_booting(self):
        # Placeholder, override to start something during the bootup sequence
        if self.indicator:
            self.indicator.turn_on(flash_on_duration=0.5)

    def indicate_booting_done(self, message):
        # Boot sequence has completed, turn off booting visualization
        # Override if visualization is done differently
        if self.indicator:
            self.indicator.turn_off()

    def indicate_sleeping(self, message):
        # Turn lights when asleep
        if self.indicator:
            self.indicator.turn_off()
        self.asleep = True

    def indicate_waking(self, message):
        if self.indicator:
            self.indicator.turn_on(flash_on_duration=0.25)
        sleep(2)
        if self.indicator:
            self.indicator.turn_off()
        self.asleep = False

    ######################################################################
    # Basic button support.  By default behave like the Mark 1 button where
    # pressing it either stops a current action or starts listening
    #
    # Override these actions to react to button events
    # NOTE: Basic "button click" actions should happen on the Release instead
    #       of the Press.  This allows the Held to occur without triggering
    #       a "button click".

    def on_button_pressed(self):
        """ The button has been depressed once """
        pass

    def on_button_double_press(self):
        """ The button has been depressed within 1 sec of a previous pressing

        NOTE:  No on_button_pressed() is generated for the second press.
        """
        pass

    def on_button_held(self):
        """ The button has been pressed and held for a second """
        pass

    def on_button_released(self):
        """ The button has been released after a press

        NOTE: No on_button_released() occurs when held or double-pressed.
        """
        # Generate a Listen/Stop signal like the top button press on a Mark 1.
        create_signal('buttonPress')
        self.bus.emit(Message("mycroft.stop"))

    ######################################################################
    # Interaction sequence indicators.  The trypical sequence is:
    # - indicate_listening()
    # - indicate_listening_done()
    # - indicate_thinking()
    # - indicate_talking()
    # - indicate_talking_done()
    # - indicate_thinking_done()
    # There are variations on this, for example an inadvertant recording might
    # begin a handler, thus no "thinking".  Or there might be multiple talking
    # sequences within once thinking session.

    # Illuminate lights when listening
    def indicate_listening(self, message):
        if self.asleep or not self.indicator:
            return
        self.indicator.turn_on()

    def indicate_listening_done(self, message):
        if self.asleep or not self.indicator:
            return
        self.indicator.turn_off()

    def indicate_thinking(self, message):
        if self.asleep or not self.indicator:
            return
        self.indicator.turn_on()

    def indicate_thinking_done(self, message):
        if self.asleep or not self.indicator:
            return
        self.indicator.turn_off()

    def indicate_talking(self, message):
        if self.asleep or not self.indicator:
            return
        self.indicator.turn_on(flash_on_duration=0.25)

    def indicate_talking_done(self, message):
        if self.asleep or not self.indicator:
            return
        self.indicator.turn_off()

    ######################################################################
    # Administrative actions
    #
    # Many of the following require root access, but can operate because
    # this process is launched using sudo.

    def on_software_update(self, message):
        # Mycroft updates itself on reboots
        self.speak("Updating system, please wait")
        sleep(5)
        os.system("cd /home/pi/mycroft-core && git pull")
        sleep(2)

        self.speak("Rebooting to apply update")
        sleep(5)
        if self.indicator:
            self.indicator.turn_off()
        os.system("shutdown --reboot now")

    def on_shutdown(self, message):
        if self.indicator:
            self.indicator.turn_off()
        os.system("shutdown --poweroff now")

    def on_reboot(self, message):
        # Example of using the self.speak() helper function
        self.speak("I'll be right back")
        sleep(5)
        if self.indicator:
            self.indicator.turn_off()
        os.system("shutdown --reboot now")

