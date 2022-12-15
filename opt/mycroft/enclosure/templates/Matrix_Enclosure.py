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
#   * A button connected to the GPIO-23 (and ground) as a Stop button
#   * LED activity light on GPIO-21
#   * Administrative actions such as reboot and shutdown
#
# Feel free to modify this code to your own purposes.  Changes will not be
# overwritten by the update process will not change it.  This code monitors
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

watchdog.watch(__file__)

##########################################################################

class Matrix_Enclosure(Picroft_Enclosure):

    def __init__(self):
        super().__init__()

    # TODO: Use the Matrix light array to indicate status


enc = Matrix_Enclosure()
enc.run()
