#! /usr/bin/env python
#-------------------------------------------------------------------------------
# Name:        Remote Control Receiver 
# Purpose:     Receiving remote control commands, controlling 
#              seros, H-Bridges and digital outputs using a PCA9685 board     
# Author:      Bernd Hinze
#
# Created:     10.04.2019
# Copyright:   (c) Bernd Hinze 2019
# Licence:     MIT see https://opensource.org/licenses/MIT
# -----------------------------------------------------------------------------
import time
from rcapp import PWM_Controller, UDP_Client, Observer, SIM


def main():
    # Configuration general prototype
    # Channel 0,1,2: L298 H-Bridge
    # Channel 4: Servo
    # Channel 6: Status LED that is illuminated at live time
    if not SIM:
        time.sleep(10)  
    L298Channels = [0, 1, 2]
    DIOs = [6]
    Inverted = [6]  
    SC = PWM_Controller(1.0, 2.0, 50, L298Channels, DIOs, Inverted)
    #SC.set_fail_save_pos(0, 0)
    SC.fail_safe()
    SC.update_ch(6, 254) # live indication after start up (LED)
    S = UDP_Client(SC,'', 6000, 6100, 10, "RC#001")
    O = Observer(SC, 30.0, "RC#001")


if __name__ == '__main__':
    main()
