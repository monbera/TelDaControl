# Copyright (c) 2016 Adafruit Industries
# Author: Tony DiCola
# Original source has been revised for own purposes
#-----------------------------------------------------------------------------
# Name:        Device driver for PCA9685 board 
# Purpose:     Modification without using the GPIO library, direct 'smb' usage 
#              Additional method for GPOs
#             
# Author:      Bernd Hinze
#
# Created:     08.01.2019
# Copyright:   (c) Bernd Hinze 2019
# Link:        https://github.com/monbera/TeleControl.git 
# Licence:     MIT see https://opensource.org/licenses/MIT
# ----------------------------------------------------------------------------
from __future__ import division
import time

SIM = False
 
if SIM:
    class Sbus():
        def __init__(self):
            pass                   
        def write_byte_data(self, dev, reg, val):
            pass
            #print (hex(dev), hex(reg), hex(val))  
        def read_byte_data(self, dev, reg):
            return 0x00
        
    bus = Sbus()
else:
    import smbus
    bus = smbus.SMBus(1)
    
PCA9685_ADDR       = 0x40
MODE1              = 0x00
MODE2              = 0x01
SUBADR1            = 0x02
SUBADR2            = 0x03
SUBADR3            = 0x04
PRESCALE           = 0xFE
LED0_ON_L          = 0x06
LED0_ON_H          = 0x07
LED0_OFF_L         = 0x08
LED0_OFF_H         = 0x09
ALL_LED_ON_L       = 0xFA
ALL_LED_ON_H       = 0xFB
ALL_LED_OFF_L      = 0xFC
ALL_LED_OFF_H      = 0xFD

# Bits:
RESTART            = 0x80
SLEEP              = 0x10
ALLCALL            = 0x01
INVRT              = 0x10
OUTDRV             = 0x04

class PCA9685():
    def __init__(self):
        ''' 
        '''          
        self.set_all_pwm (0,0)
        bus.write_byte_data(PCA9685_ADDR, MODE2, OUTDRV)
        bus.write_byte_data(PCA9685_ADDR, MODE1, ALLCALL)
        time.sleep(0.005)
        mode1 = bus.read_byte_data(PCA9685_ADDR, MODE1)
        mode1 = mode1 & ~SLEEP
        bus.write_byte_data(PCA9685_ADDR, MODE1, mode1)
        time.sleep(0.005)

    def software_reset(self):
        bus.write_byte_data(0x00, 0x06)

    def set_pwm_freq(self, hz):
        """Set the PWM frequency to the provided value in hertz."""
        prescale = int( round (25000000 / (4096 * hz)))
        oldmode = bus.read_byte_data(PCA9685_ADDR, MODE1);
        newmode = (oldmode & 0x7F) | SLEEP
        bus.write_byte_data(PCA9685_ADDR, MODE1, newmode)
        bus.write_byte_data(PCA9685_ADDR, PRESCALE, prescale)
        bus.write_byte_data(PCA9685_ADDR, MODE1, oldmode)
        time.sleep(0.005)
        bus.write_byte_data(PCA9685_ADDR, MODE1, oldmode | RESTART)

    def set_pwm(self, chnl, on, off):
        """Sets a single PWM channel."""
        bus.write_byte_data(PCA9685_ADDR, LED0_ON_L + (4 * chnl), on & 0xFF)
        bus.write_byte_data(PCA9685_ADDR, LED0_ON_H  + (4 * chnl), on >> 8)
        bus.write_byte_data(PCA9685_ADDR, LED0_OFF_L + (4 * chnl), off & 0xFF)
        bus.write_byte_data(PCA9685_ADDR, LED0_OFF_H + (4 * chnl), off >> 8)  
                       
    def set_all_pwm(self, on, off):
        """Sets all PWM channels."""
        bus.write_byte_data(PCA9685_ADDR, ALL_LED_ON_L, on & 0xFF)
        bus.write_byte_data(PCA9685_ADDR, ALL_LED_ON_H, on >> 8)
        bus.write_byte_data(PCA9685_ADDR, ALL_LED_OFF_L, off & 0xFF)
        bus.write_byte_data(PCA9685_ADDR, ALL_LED_OFF_H, off >> 8)

    def set_dio(self, chnl, state):
        """ state == 0 => OFF, state != 0  => ON 
        """
        if (state == 0):  
            bus.write_byte_data(PCA9685_ADDR, LED0_ON_L  + (4 * chnl), 0x00)
            bus.write_byte_data(PCA9685_ADDR, LED0_ON_H  + (4 * chnl), 0x00)
            bus.write_byte_data(PCA9685_ADDR, LED0_OFF_L  + (4 * chnl), 0x00)
            bus.write_byte_data(PCA9685_ADDR, LED0_OFF_H  + (4 * chnl), 0x10)
        else:  
            bus.write_byte_data(PCA9685_ADDR, LED0_ON_L  + (4 * chnl), 0x00)
            bus.write_byte_data(PCA9685_ADDR, LED0_ON_H  + (4 * chnl), 0x10)
            bus.write_byte_data(PCA9685_ADDR, LED0_OFF_L  + (4 * chnl), 0x00)
            bus.write_byte_data(PCA9685_ADDR, LED0_OFF_H  + (4 * chnl), 0x00)


if __name__ == "__main__":
    B = PCA9685()
    B.set_pwm_freq(50)
    B.set_pwm(4, 0, 205)
    time.sleep(2)
    B.set_pwm(4, 0, 410)
            
        

        



            
                
         


