#!/usr/bin/env python
##########################################################################
# gpio_button.py
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
from time import time

class GPIO_Button:

    def __init__(self, GPIO_BCM=23, on_press=None, on_release=None,
                 on_hold=None, on_double_press=None):
        """ Interface for a button connected to a GPIO pin

        Respond to a button connected to a GPIO pin (and ground)

        Args:
            GPIO_BCM (int, optional): The BCM number of the GPIO pin to use.
                                      Defaults to 23.
        """
        self.button_bcm = GPIO_BCM

        self._on_press = on_press
        self._on_release = on_release
        self._on_hold = on_hold
        self._on_double_press = on_double_press

        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self.button_bcm, GPIO.IN, pull_up_down=GPIO.PUD_UP)
        GPIO.add_event_detect(23, GPIO.BOTH, self._on_gpio_button)
        self.__timer = None
        self.__timer2 = None
        self.__last_press = 0
        self.__pressed = False
        self.__double_pressed = False

    def __del__(self):
        GPIO.remove_event_detect(self.button_bcm)

    def _on_gpio_button(self, channel):
        if GPIO.input(channel) == GPIO.HIGH:
            # High == button unpressed (pulled high to 3.3v)
            self.__pressed = False
            if self.__timer:
                self.__timer.cancel()
            if self.__timer2:
                self.__timer2.cancel()
            # Wait briefly before firing event to de-bounce
            self.__timer = Timer(0.05, self._on_gpio_released)
            self.__timer.start()
        else:
            # Low == button pressed (grounded)
            self.__pressed = True
            if self.__timer:
                self.__timer.cancel()
            if self.__timer2:
                self.__timer2.cancel()
            # Wait briefly before firing event to de-bounce
            self.__timer = Timer(0.05, self._on_gpio_pressed)

            # Hold for 1 second to get a "hold" action
            self.__timer2 = Timer(1, self._on_gpio_held)
            self.__timer.start()
            self.__timer2.start()

    def _on_gpio_pressed(self):
        self.__timer = None
        if self.__pressed:
            now = time()
            time_since_last = now - self.__last_press
            self.__last_press = now
            if time_since_last < 1:
                # Two presses within a second == double press event
                self.__double_pressed = True
                if self._on_double_press:
                    self._on_double_press()
            else:
                # Single press event
                self.__double_pressed = False
                if self._on_press:
                    self._on_press()

    def _on_gpio_released(self):
        self.__timer = None
        if not self.__pressed and not self.__double_pressed:
            if time() - self.__last_press < 1:
                # Release event
                if self._on_release:
                    self._on_release()
            else:
                # Either button was held or a spurrious signal with no press
                pass

    def _on_gpio_held(self):
        self.__timer2 = None
        if self.__pressed:
            # Button held event
            if self._on_hold:
                self._on_hold()
