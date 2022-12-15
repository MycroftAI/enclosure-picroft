#!/usr/bin/env python
##########################################################################
# Generic_Enclosure.py
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

# This file defines a basic enclosure for your Picroft. By default it supports:
#   * LED activity light on GPIO-21
#   * A button connected to the GPIO-23 (and ground) as a Stop button
#   * Administrative actions such as reboot and shutdown
#
# Feel free to modify this code to your own purposes.  Changes will not be
# overwritten by the update process will not change it.  This code monitors
# the messagebus for system events, listens to GPIOs, and can do just about
# anything you'd like.
#
# Changes to my_enclosure.py will restart the enclosure process automatically
# but be careful -- syntax errors will require manual relaunching or reboot
# after the error is fixed.

from lib.picroft_enclosure import Picroft_Enclosure
from time import sleep

import lib.file_watchdog as watchdog
watchdog.watch(__file__)

##########################################################################

class Generic_Enclosure(Picroft_Enclosure):

    def __init__(self):
        super().__init__(button_gpio_bcm=23, led_gpio_bcm=21)

enc = Generic_Enclosure()
enc.run()
