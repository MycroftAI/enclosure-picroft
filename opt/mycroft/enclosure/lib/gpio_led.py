#!/usr/bin/env python
##########################################################################
# gpio_led.py
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

import RPi.GPIO as GPIO
from threading import Timer

class GPIO_LED:

    def __init__(self, GPIO_BCM=21):
        """ Interface with an LED connected to a GPIO pin

        Control an LED connected to a GPIO pin (and ground)

        Args:
            GPIO_BCM (int, optional): The BCM number of the GPIO pin to use.
                                      Defaults to 21.
        """
        super().__init__()
        self.led_bcm = GPIO_BCM
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self.led_bcm, GPIO.OUT)
        self.__timer = None

    def turn_on(self, flash_on_duration=None, flash_off_duration=0.1):
        """ Turn on the LED and optionally flash it

        Args:
            flash_on_duration (float, optional): Seconds to remain lit,
                                                 or None for constant.
            flash_off_duration (float, optional): Seconds to go dark.
                                                  Defaults to 0.1.
        """
        if self.__timer:
            self.__timer.cancel()
            self.timer = None
        GPIO.output(self.led_bcm, GPIO.HIGH)
        if flash_on_duration:
            self.__timer = Timer(flash_on_duration, self.__flasher,
                                 [True, flash_on_duration, flash_off_duration])
            self.__timer.start()

    def turn_off(self):
        """ Illuminate the LED """
        if self.__timer:
            self.__timer.cancel()
            self.timer = None
        GPIO.output(self.led_bcm, GPIO.LOW)

    def __flasher(self, is_on, on_duration, off_duration):
        if self.__timer:
            self.__timer.cancel()
            self.timer = None
        if is_on:
            GPIO.output(self.led_bcm, GPIO.HIGH)
            next_change = off_duration
        else:
            GPIO.output(self.led_bcm, GPIO.LOW)
            next_change = on_duration
        self.__timer = Timer(next_change, self.__flasher,
                             [not is_on, on_duration, off_duration])
        self.__timer.start()
