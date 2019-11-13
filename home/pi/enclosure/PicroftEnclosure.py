#!/usr/bin/env python
##########################################################################
# PicroftEnclosure.sh
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

# This file defines a custom enclosure for your Picroft.  Feel free to modify
# it, the automatic update process will not overwrite it.  This code can
# monitor the messagebus for system events, listen to GPIOs, or do just about
# anything you'd like.
#
# Changes made to the file will restart the enclosure process automatically
# but be careful -- syntax errors will require manual relaunching or reboot
# after the error is fixed.  Relaunch manually via:
#    cd ~/enclosure
#    python PicroftEnclosure.py


from mycroft.client.enclosure.generic import EnclosureGeneric
from time import sleep

##########################################################################
# Watchdog to reload this script upon modification

import os, sys
import threading
from os.path import getmtime
WATCHED_FILES = [__file__]  # Add other dependencies as desired, e.g. "my.json"
WATCHED_FILES_MTIMES = [(f, getmtime(f)) for f in WATCHED_FILES]

def checkForModification():
    for f, mtime in WATCHED_FILES_MTIMES:
        if getmtime(f) != mtime:
            # Code modification detected, restarting!
            os.execv(sys.executable, ['python'] + sys.argv)
    threading.Timer(5, checkForModification).start()

# Kick-off monitor (starts a 5 second timer at the end)
checkForModification()

##########################################################################

class EnclosurePicroft(EnclosureGeneric):

    def __init__(self):
        super().__init__()

        # Messagebus listeners
        self.bus.on("system.shutdown", self.handle_shutdown)
        self.bus.on("system.reboot", self.handle_reboot)

    def handle_shutdown(self, message):
        os.system("shutdown --poweroff now")

    def handle_reboot(self, message):
        # Example of using the self.speak() helper function
        self.speak("I'll be right back")
        sleep(5)

        os.system("shutdown --reboot now")

    # TODO: Add example GPIO watcher for a contact button?

    # TODO: GUI handler example (e.g. for magic mirror)


enc = EnclosurePicroft()
enc.run()

