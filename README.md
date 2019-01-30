# Funkfernsteuerung 

## Übersicht

Abbildung 1 zeigt die Systemübersicht  einer Funkfernsteuerung für Modelle. Das System besteht aus einem Raspberry Pi als Empfänger mit einem 12-Bit-PWM-Modul, das über eine I2C-Schnittstelle mit dem Raspberry verbunden ist. An das PWM-Modul können bis zu 16 Stellglieder angeschlossen werden. Servos, digitale I/O-Stellglieder wie LEDs oder Relais und H-Brücken können verwendet werden.  Als Fernsteuer Sender wird eine Anwendung verwendet, die entweder auf einem normalen Mobiltelefon, Tablett oder während der Testphase auf einem PC läuft. Beide Komponenten kommunizieren über zyklische UDP-Telegramme und sind in einem lokalen WiFi-Netzwerk registriert. Für kürzere Distanzen reicht dafür auch die Hotspotfunktion des Mobiltelefon. 

Der Ordner 'sw' enthält drei Unterverzeichnisse mit jeweils speziellen Applikationen.

>[./sw/RCPC](./sw/RCPC)  -  PC Applikation des Senders
>[./sw/TelDaControl](/sw/TelDaControl)  -  Android Applikation des Senders
>[./sw/Rpi](./sw/Rpi)-  Applikation des Empfängers (Raspberry Pi)


# Radio Remote Control

## Overview

Figure 1 shows the system overview of a radio remote control for models. The system consists of a Raspberry Pi receiver with a 12-bit PWM module connected to the Raspberry via an I2C interface. Up to 16 actuators can be connected to the PWM module. Servos, digital I/O actuators such as LEDs or relays and H-bridges can be used.  The remote control transmitter is an application that runs either on a normal mobile phone, tablet or during the test phase on a PC. Both components communicate via cyclic UDP telegrams and are registered in a local WiFi network. The hotspot function of the mobile phone is sufficient for shorter distances. 

The 'sw' folder contains three subdirectories, each with its own special applications.
>[./sw/RCPC](./sw/RCPC) - PC application of the transmitter
>[./sw/TelDaControl](/sw/TelDaControl)  - Android application of the transmitter
>[./sw/Rpi](./sw/Rpi) - Application of the receiver (Raspberry Pi)

Translated with www.DeepL.com/Translator




![Overview](./pic/Overview.png  "System Overview")

Abbildung/Figure 1: Systemübersicht/ System Overview

Since I do not want to maintain 2 documents only a documentation in English is available. 
You will find the complete documentation in the [./doc](./doc)  folder. 