#!/bin/bash
##########################################################################
# file_watchdog.py
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

# Gain root access (needed for GPIO and Admin actions), load the Mycroft
# virtual environment, and launch the enclosure script
sudo -- bash -c 'source /home/pi/mycroft-core/venv-activate.sh; python3 my_enclosure.py'
