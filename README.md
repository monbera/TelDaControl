# Overview

Figure 1 shows an overview of the system. The system consists of a Raspberry Pi receiver and a 12-bit PWM module connected to the Raspberry via I2C interface. Up to 16 actuators can be connected to the PWM module. Servos, digital I/O actuators such as LEDs or relays and H-bridges can be used. Optionally, other sensors can be connected directly to the Raspberry, e.g. a GPS module, a distance sensor, a camera or acoustic and optical signal transmitters. As remote control transmitter an application is used, which either runs on a normal mobile phone, tablet, or does its job during the test phase on a PC. Both components communicate via cyclic UDP telegrams and are registered in a local WiFi network.

Translated with www.DeepL.com/Translator

Since I did not want to maintain 2 documents, I decided to publish the documentation exclusively in English. 


![Overview](./pic/Overview.png  "System Overview")

Figure 1: System Overview

You will find the complete documentation in the [./doc](./doc)  folder. 