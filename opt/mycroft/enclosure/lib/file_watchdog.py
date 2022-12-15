#!/usr/bin/env python
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

##########################################################################
# This implements a watchdog to reload the given script(s) when changes
# are made to the files.  In other words, it automatically restarts the given
# program when the program or other watched files are edited and saved to disk.
#
# Usage:
#   import lib.file_wachdog as watchdog
#   watchdog.watch(__file__)

import os, sys
import threading
from os.path import getmtime

__watched_files_mtimes = []


def __checkForModification():
    for f, mtime in __watched_files_mtimes:
        if getmtime(f) != mtime:
            # Code modification detected, re-launch the main program to
            # pick up the changes.
            return os.execv(sys.executable, ['python'] + sys.argv)

    # Rerun the check in 5 seconds
    t = threading.Timer(5, __checkForModification)
    t.daemon = True  # don't block the program from ending if main block exits
    t.start()


def watch(files):
    """Start watchdog to relaunch the program when the file(s) change

    Args:
        files (string or [string]): File(s) to monitor for changes
    """
    global __watched_files_mtimes

    if isinstance(files, list):
        __watched_files = files
    else:
        __watched_files = [files]  # support a single filename
    __watched_files_mtimes = [(f, getmtime(f)) for f in __watched_files]

    # Kick-off monitor which checks every 5 seconds for code changes
    __checkForModification()
