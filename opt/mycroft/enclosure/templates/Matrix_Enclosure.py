#!/usr/bin/env python
##########################################################################
# Matrix_Enclosure.sh
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

# This file defines a simple custom enclosure for your Picroft.  By default
# it supports:
#   * A GPIO button connected as a "Stop"
#   * A GPIO LED as an activity indicator
#   * Reboot and shutdown administrative actions
#
# Feel free to modify this code to your own purposes.  Changes will not be
# overwritten by the update process will not overwrite it.  This code monitors
# the messagebus for system events, listens to GPIOs, and can do just about
# anything you'd like.
#
# Changes made to the file will restart the enclosure process automatically
# but be careful -- syntax errors will require manual relaunching or reboot
# after the error is fixed.  Relaunch manually via:
#    cd ~/enclosure
#    python ~/my_enclosure.py

from mycroft.client.enclosure.generic import EnclosureGeneric
from time import sleep
import RPi.GPIO as GPIO
import os, sys
import threading
from os.path import getmtime

##########################################################################
# Watchdog to reload this script upon modification of this file

WATCHED_FILES = [__file__]  # Add other dependencies as desired, e.g. "my.json"
WATCHED_FILES_MTIMES = [(f, getmtime(f)) for f in WATCHED_FILES]

def checkForModification():
    for f, mtime in WATCHED_FILES_MTIMES:
        if getmtime(f) != mtime:
            # Code modification detected, restarting!
            os.execv(sys.executable, ['python'] + sys.argv)
    threading.Timer(5, checkForModification).start()

# Kick-off monitor checks every 5 seconds for code changes in this file
checkForModification()


##########################################################################

# BCM GPIO numbers
GPIO_LED = 25
GPIO_BUTTON = 23

class Matrix_Enclosure(EnclosureGeneric):

    def __init__(self):
        super().__init__()

        # Administrative messages
        self.bus.on("system.shutdown", self.on_shutdown)
        self.bus.on("system.reboot", self.on_reboot)
        self.bus.on("system.update", self.on_software_update)

        # Interaction feedback
        self.bus.on("recognizer_loop:wakeword", self.on_wakeword)
        self.bus.on("recognizer_loop:record_begin", self.on_record_begin)
        self.bus.on("recognizer_loop:record_end", self.on_record_end)
        self.bus.on("recognizer_loop:sleep", self.on_sleep)
        self.bus.on("recognizer_loop:wake_up", self.on_wake_up)
        self.bus.on("recognizer_loop:audio_output_start", self.on_output_start)
        self.bus.on("recognizer_loop:audio_output_end", self.on_output_end)
        self.bus.on("mycroft.skill.handler.start", self.on_handler_start)
        self.bus.on("mycroft.skill.handler.complete", self.on_handler_end)

        # Visual indication that system is booting
        self.bus.on("mycroft.skills.initialized", self.on_ready)

        # Setup to support a button on a GPIO
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(GPIO_BUTTON, GPIO.IN)
        GPIO.add_event_detect(GPIO_BUTTON, GPIO.BOTH, self.on_gpio_button)
        
        # Setup to support a LED on selected GPIO
        GPIO.setup(GPIO_LED, GPIO.OUT)

        self.asleep = False

    def on_ready(self, message):
        # Boot has completed, turn off booting visualization
        GPIO.output(GPIO_LED, 0)

    def on_sleep(self, message):
        # Turn lights orange when asleep
        GPIO.output(GPIO_LED, 0)
        self.sleep = True

    def on_wake_up(self, message):
        GPIO.output(GPIO_LED, 1)
        sleep(2)
        GPIO.output(GPIO_LED, 0)
        self.sleep = False

    ######################################################################
    # Interaction sequence indicators.  The trypical sequence is:
    # - Wakeword heard
    # - Recording begins
    # - Recording ends
    # - Handler starts
    # - Output begins
    # - Output ends
    # - Handling ends
    # There are variations on this, for example an inadvertant recording might never
    # begin a handler sequence.  Or there might be multiple output begin/end pairs
    # within the handler.

    # Illuminate lights when listening
    def on_wakeword(self, message):
        if self.sleep:
            return
        GPIO.output(GPIO_LED, 1)

    def on_record_begin(self, message):
        if self.sleep:
            return
        GPIO.output(GPIO_LED, 1)

    def on_record_end(self, message):
        if self.sleep:
            return
        GPIO.output(GPIO_LED, 0)

    def on_handler_start(self, message):
        if self.sleep:
            return
        GPIO.output(GPIO_LED, 1)

    def on_handler_end(self, message):
        if self.sleep:
            return
        GPIO.output(GPIO_LED, 0)

    def on_output_start(self, message):
        if self.sleep:
            return
        GPIO.output(GPIO_LED, 1)

    def on_output_end(self, message):
        if self.sleep:
            return
        GPIO.output(GPIO_LED, 0)

    ######################################################################
    # Simple button support
    #
    # Wire a button between ground and the GPIO to create a "Stop" button, like
    # on a Mycroft Mark 1.  The button can also initialize listening without
    # speaking the wakeword.

    def on_gpio_button(channel):
        if GPIO.input(channel) == GPIO.HIGH:
            # Stop Button pressed, similar to the Mark 1
            self.bus.emit(Message("mycroft.stop"))
        else:
            # Button released
            pass

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
        os.system("shutdown --reboot now")

    def on_shutdown(self, message):
        os.system("shutdown --poweroff now")

    def on_reboot(self, message):
        # Example of using the self.speak() helper function
        self.speak("I'll be right back")
        sleep(5)
        os.system("shutdown --reboot now")


enc = Matrix_Enclosure()
enc.run()
