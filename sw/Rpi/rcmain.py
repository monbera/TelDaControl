#! /usr/bin/env python3
# -*- coding: utf-8 -*-
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
from rcapp import PWM_Controller, UDP_Client, Observer, Utility, logfolder, \
    lfprefix


def main():
    rcname = "RC#001"
    # Configuration general prototype
    # Channel 0,1,2: L298 H-Bridge
    # Channel 4: Servo
    # Channel 6: Status LED that is illuminated at live time
    Utility.del_files(logfolder, lfprefix , 10)
    while (Utility.get_ip_address('wlan0') == "127.0.0.0"):
        print ("waiting for networking")
        time.sleep(1) 
    L298Channels = [0, 1, 2]
    DIOs = [6]  
    # inverted channels
    Inverted = [6] 
    SC = PWM_Controller(1.0, 2.0, 50, L298Channels, DIOs, Inverted)
    SC.set_fail_save_pos(0, 127)
    SC.fail_safe()
    SC.update_ch(6, 254) # live indication after start up (LED)
    U = UDP_Client(SC,'', 6000, 6100, 10, rcname)
    O = Observer(SC, 1.0)
    O.start()
    U.run()


if __name__ == '__main__':
    main()
