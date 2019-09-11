#! /usr/bin/env python3
# -*- coding: utf-8 -*-
#-------------------------------------------------------------------------------
# Name:        Remote Control Receiver 
# Purpose:     Receiving remote control commands, controlling 
#              servos, H-Bridges and digital outputs using a PCA9685 board     
# Author:      Bernd Hinze
#
# Created:     30.04.2019
# Copyright:   (c) Bernd Hinze 2019
# Licence:     MIT see https://opensource.org/licenses/MIT
# -------------------------------------------------------------------------------
from __future__ import division, print_function
import netifaces as ni
import socket
import time
import os
import queue
import logging
from threading import Thread
from pca9685 import PCA9685, SIM   # PWM Board Package

q = queue.LifoQueue(100)
if not SIM: 
    logfolder = '/home/pi/prj/tmp'
else:
    logfolder = os.getcwd() + '/tmp'
lfprefix = 'rc_rec'
if not os.access(logfolder, os.F_OK):
    os.mkdir(logfolder, 0o766)
boottime = time.strftime('%d%m%y_%X')
logfname = logfolder +'/' + lfprefix + '_' + str(boottime) + '.log'
log = logging.getLogger(__name__)
log.setLevel(logging.INFO)
fh = logging.FileHandler(logfname, 'w')
formatter = logging.Formatter('%(asctime)s %(message)s')
fh.setFormatter(formatter)
log.addHandler(fh)

if SIM: 
    ch = logging.StreamHandler() 
    ch.setFormatter(formatter)
    log.addHandler(ch)

log.info("Start Script rcapp.py")

class Utility(): 
    ''' Static methods to get IP-adresses
    '''
    def get_ip_address(ifname):
        try:
            return ni.ifaddresses(ifname)[ni.AF_INET][0]['addr']
        except:
            return "127.0.0.0"
             
    def get_bc_address(ifname):
        ip = Utility.get_ip_address(ifname).split('.')
        bcip = ip[0] + '.' + ip[1] + '.' + ip[2] + '.' + '255'
        return bcip
               
    def del_files(folder , fileprfix, cnt_reamin):
        ''' 
        deletes all old files in a directory with a special prefix 
        so that an amount of newer files remains given with the parameter
        '''
        if not os.access(folder , os.F_OK):
            log.debug ('Folder not found')
        else:
            filelist = os.listdir(folder)            
            filetime = []
            if (len(filelist) > cnt_reamin):
                slicer =  (len(filelist)) - cnt_reamin
            else:
                slicer = 0
            for file in filelist:
                t = int(os.stat(folder + '//' + file).st_atime)
                filetime.append(t)
            filetime.sort() 
            for file in filelist:
                t = int(os.stat(folder + '//' + file).st_atime)
                if t in (filetime[:slicer]): 
                    if (fileprfix == file[0:len(fileprfix)]):
                        os.remove(folder + '//' + file)       


    get_ip_address = staticmethod(get_ip_address)
    get_bc_address = staticmethod(get_bc_address)
    del_files = staticmethod(del_files)

class PWM_Controller(PCA9685):
    ''' Extends the PCA9685 class with a user specific API.
    
    Parameter: 
        i_min, i_max: Default lower and upper value of servo pulse time [ms]
        freq        : Frequency of pca9685 cyclic in [Hz]
        L298s       : List of channels that controls a L298 H-bridge
                      [channel, EN1, EN2]
        Dios        : List of channels that controls digital outputs
        Inv         : List of channels that has to be inverted
    Variables:
        self.imp_tab = []  - 16 x 254 cells table, containing the 
                             impulse parameter for each servo value of channel
                             used by the PCA9685 device driver
        self.FSave = [] -    Stores the fail-save servo value of each channel
        self.ChTidef = [],[] - Stores the min and diff = max - min value 
                              of pulses for each channel
    Public methods: 
        get_rtime(): Provides the realtime the controller was updated 
        update(msg): Updates a channel with a new set value 
        adjust_channel (min_val, max_val, ch): 
                     Can be used to specify 
                     lower and upper value of servo pulse time [ms] for a 
                     special channel, like a pretrimming
        adjust_dual_rate (self, ch, fval):
                     The value 'fval' (0..100) sets the impulsrates new in the 
                     self.imp_tab for the channel 'ch'
        set_fail_save_pos(chan, val):
                     Overrides the predefined settings of 
                     fail-save value for a special channel
        fail_safe(): Sets all actuators to the fail-save position
                      
    '''
    def __init__(self, i_min, i_max, freq, L298s = [], Dios=[], Inv = []):
        PCA9685.__init__(self)
        self.freq = freq
        self.set_pwm_freq(self.freq) 
        self.i_min = i_min
        self.i_max = i_max
        self.L298Chs = L298s
        self.Dios = Dios
        self.Inv = Inv       
        self.FSave = []     
        self.imp_tab = []
        self.invert_input = []
        self.ChTidef = [],[]  
        # Fills the fail_safe position list with default values
        for i in range(16):
            self.FSave.append(127)           
        (self.ix_min, self.ix_diff) = range(2)        
        # Fills the channel time behavior list with default values
        for i in range(16):
            self.ChTidef[self.ix_min].append(self.imp_val(self.i_min))            
            self.ChTidef[self.ix_diff].append(self.diff_val(self.i_min, self.i_max))         
        self.calc_puls_table()
        # update of pulstable for LM298 purposes
        i = 0
        for i in range(len(self.L298Chs)):
            if (i % 3 == 0):
                self.calc_puls_table_L298(self.L298Chs[i]) 
        self.create_invert_table()
        
    def get_rtime(self):
        return self.rtime

    def create_invert_table (self):
        ri = 254
        for i in range (255):
            self.invert_input.append(ri - i )
            
    def calc_puls_table (self):
        """ 
        """
        for c in range (16):
            ptab = []
            for i in range(255):                 
                ptab.append(int((self.ChTidef[self.ix_diff][c] * i/254) + \
                                self.ChTidef[self.ix_min][c])) 
            self.imp_tab.append(ptab) 
            
    def imp_val (self, val):
        return int(round(((val * self.freq) / 1000) * 4095))
    
    def diff_val (self, min_val, max_val):
        return self.imp_val(max_val) - self.imp_val(min_val)
    
    def adjust_channel (self, ch, min_val, max_val):
        self.ChTidef[self.ix_min][ch] = self.imp_val(min_val)       
        self.ChTidef[self.ix_diff][ch] = self.diff_val(min_val, max_val)
        for i in range(255):                 
                self.imp_tab[ch][i]=(int((self.ChTidef[self.ix_diff][ch] * i/254) \
                        + self.ChTidef[self.ix_min][ch]))

    # ch: channel, fval = Thresshold 0..100 
    def adjust_threshold (self, ch, fval):
        ndiff =(self.ChTidef[self.ix_diff][ch] * fval/100.0)
        nmin = ((self.ChTidef[self.ix_min][ch]  \
                 + (self.ChTidef[self.ix_diff][ch]/2)) - ndiff/2)
        for i in range(255):                 
                self.imp_tab[ch][i]=int((ndiff * i/254) + nmin) 

    def calc_puls_table_L298 (self, chan):
        """ call after 'calc_puls_table'
        """
        tab  = []
        diff =  4095
        for i in range (255):
            if (i <= 127):
                 tab.append(int(diff -(diff * i/127)))
            else: 
                 tab.append(int(diff * (i-127)/127))
        self.imp_tab[chan] = tab                    
            
    def trimm_chan (self, ch, trimm):
        ''' trim is a value in range 0 .. 50 and shifts the 
            table values of ((trim-25)/254 * self.diff)    
        '''
        if (ch in self.L298Chs):
            pass
        else:         
            korr = (trimm - 25)/254 * self.ChTidef[self.ix_diff][ch]
            if  (trimm < 51):
                for i in range(255):
                    self.imp_tab[ch][i] = \
                        int(((self.ChTidef[self.ix_diff][ch] * i/254) \
                        + self.ChTidef[self.ix_min][ch]) + korr)  
    
    def set_fail_save_pos (self, chan, val):
        self.FSave[chan] = val

    def fail_safe(self):
        for i in range(16):
            if (i in self.Dios):
                self.update_Dio(i, self.FSave[i])
            elif (i in self.L298Chs): 
                idx = self.L298Chs.index(i)
                if (idx % 3) == 0:
                    self.update_L298(i, self.FSave[i])
            else: 
                self.update_Servo(i, self.FSave[i])  
                
    def update_app (self, chan, remote_inp):
        if (remote_inp == 0):
            self.fail_safe()
            log.info("Shutdown by command")
            time.sleep(1)
            if (not SIM):
                os.system("sudo shutdown now")                                    
                               
    def update_L298(self, chan, remote_inp):
        self.set_pwm(chan, 0, self.imp_tab[chan][remote_inp])
        dio = self.L298Chs.index(chan)
        if (remote_inp < 127):          
            self.set_dio(self.L298Chs[dio+1], 0)
            self.set_dio(self.L298Chs[dio+2], 1)  
        elif (remote_inp > 127):
            self.set_dio(self.L298Chs[dio+1], 1)
            self.set_dio(self.L298Chs[dio+2], 0)  
        else: 
            self.set_dio(self.L298Chs[dio+1], 0)
            self.set_dio(self.L298Chs[dio+2], 0)  

    def update_Dio(self, chan, remote_inp): 
        self.set_dio(chan, remote_inp)
            
    def update_Servo(self, chan, remote_inp):
        self.set_pwm(chan, 0, self.imp_tab[chan][remote_inp])

    def update_ch(self, chan, remote_inp):
        inp = remote_inp    
        if (chan in self.Inv):
            inp = self.invert_input[remote_inp]              
        if (chan in self.Dios): 
            self.update_Dio(chan, inp)
        elif (chan in self.L298Chs):    
            self.update_L298(chan, inp)
        else: 
            self.update_Servo(chan, inp)            
                
    def update(self, msg):  
        ''' Interface for the UDP-client 
        hdr = 100 : update_app | hdr = 127 : trimming |hdr = 255 : servo values            
        hdr = 105 : setting limited rate  
        '''
        if not q.full(): 
            q.put(time.time(), block=False)
        cntloop = len(msg)//3
        for i in range(cntloop): 
            hdr = msg[i*3]
            y = i*3
            if (hdr == 255):
                self.update_ch(msg[y+1], msg[y+2])           
            elif (hdr == 127):
                self.trimm_chan(msg[y+1], msg[y+2])
            elif (hdr == 100):
                self.update_app(msg[y+1], msg[y+2])
            elif (hdr == 105):
                self.adjust_threshold(msg[y+1], msg[y+2])
                

class Observer(Thread):
    ''' Timeout supervision of receiving telegrams.
        
    Depending on running in a real system or during testing on a PC 
    different actions are possible to define. 
    '''
    
    def __init__(self, SC, tel_time_out):
        Thread.__init__(self)
        self.SC = SC
        self.tout = tel_time_out
        self.tshutdn = tel_time_out * 5.0
        self.observed_time = time.time()

    def run(self):  
        time.sleep(5.0)
        while True:
            if not q.empty():
                self.observed_time = q.get()  # last time enty
            while not q.empty():
                temp = q.get()
                log.debug("queue " + str(q.qsize()))
            if ((time.time() - self.observed_time) > self.tout):
                self.SC.fail_safe()
                log.info ("Fail Save after Timeout")
                if ((time.time() - self.observed_time) > self.tshutdn):
                    if SIM:
                        log.info ("Reset requiered")
                    else:
                        os.system("sudo reboot")
            log.info("Observer running")
            time.sleep(1.0)  

class UDP_Client():    
    """  Simple UDP receiver with telegramm decoding
    
    """ 
    def __init__(self, controller, IP, port_tx, port_rx, tbroadcast, ID):
        #Thread.__init__(self)
        self.controller = controller
        self.ID = ID
        self.tbc = tbroadcast
        self.port_tx = port_tx
        self.port_rx = port_rx
        self.tout = 3.0
        self.bc_address = (Utility.get_bc_address('wlan0'), self.port_tx)
        self.bc_data = (self.ID + '@' + Utility.get_ip_address('wlan0')).encode('utf-8')
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        self.client_address = (IP, port_rx)
        self.sock.bind(self.client_address)
        self.bcTime = time.time()
        for i in range(self.tbc):
             sent = self.sock.sendto(self.bc_data, self.bc_address)        
             time.sleep(0.1)                       
  

    def run(self):  
        log.info ("Start UDP")
        while True:
            if ((time.time() - self.bcTime) > 1.0):
                self.bcTime = time.time() 
                try: 
                    sent = self.sock.sendto(self.bc_data, self.bc_address)
                    log.debug ("broadcast" + str(self.bc_data))                   
                except:
                    log.info ("Network not available - shutdown")
                    
            data , address = self.sock.recvfrom(1024)
            data = data.decode('utf-8')
            if data:
                try:
                    msg = self.decode_Tel(data)
                    log.debug (str(data))
                    self.bc_address = (address[0], self.port_tx)
                    self.update_controller(msg) 
                except:
                    msg = [] 
                    
 
    def decode_Tel(self, input):
        ''' input: string coded telegramm
            return: list of repeated channel data [hdr, chn, val, ....]
        '''
        data = []
        l = len(input)
        i = 0
        for i in range (0, l-5 , 6):
            data.append(((ord(input[i]) & 0x0F) << 4) + (ord(input[i+1]) & 0x0F)) 
            data.append(((ord(input[i+2]) & 0x0F) << 4) + (ord(input[i+3]) & 0x0F)) 
            data.append(((ord(input[i+4]) & 0x0F) << 4) + (ord(input[i+5]) & 0x0F))       
        return data 

    def update_controller(self, msg):
        self.controller.update(msg)
        

def main():
    # Configuration of the model is made in rcmain 
    pass       

if __name__ == '__main__':
    main()
