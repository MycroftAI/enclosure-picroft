#!/usr/bin/env python
##########################################################################
# AIY_Enclosure.sh
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
#   * The AIY button connected as a "Stop"
#   * The AIY button's LED as an activity indicator
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

from lib.picroft_enclosure import Picroft_Enclosure
import lib.file_watchdog as watchdog
import lib.GPIO_Button
import lib.GPIO_LED

watchdog.watch(__file__)

##########################################################################

class AIY_Enclosure(Picroft_Enclosure):

    def __init__(self):
        super().__init__()

        # Support the standard AIY button
        self.stop_button = lib.GPIO_Button(self.bus, GPIO_BCM=23)

        # Support the standard AIY button's LED as an activity indicator
        self.visual = lib.GPIO_LED(GPIO_BCM=25)


enc = AIY_Enclosure()
enc.run()
