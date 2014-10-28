rtdc
====

Remote Temperature Daughter Card (RTDC)

Uses the TMP441 with breakouts for the Power Measurement Daughter Card (PMDC) to monitor the temperature of a remote thermal diode.

This repository includes:
- Altium library, schematic, and board files
- PCB gerbers and drill files
- Bill of materials
- Linux device driver
- C code for integrating with the PMDC MSP430 source code

Using the RTDC with BeagleBone Black
The RTDC needs a 4-wire cable to interface with the BeagleBone Black. This cable connects the RTDC's power, ground, and I2C signals to the BeagleBone's P9 expansion header. The BeagleBone itself needs a power cable and communication cable, such as the FTDI/USB cable.

The AM437x contains a GND collector-connected PNP transistor, which can be used as a thermal diode to estimate junction temperature. The RTDC uses a TMP441 to monitor remote temperature of the thermal diode by using a sequential current excitation to extract a differential VBE on the transistor. The TMP441 has features to improve measurement accuracy such as beta compensation, series resistance cancellation, and ideality factor correction. These features are enabled in the script.

The RTDC plugs directly into header pins on each test platform. Be sure to align the polarity of the TEMP_DIODE signals with the RTDC's J3 receptacle; TEMP_DIODE_P is pin 1. For the GP EVM, the connecting header is J29. The SK EVM does not have the TEMP_DIODE signals broken out, so the RTDC cannot be used.

It should look something like this:


Script
Boot an Arago image on the BeagleBone Black and run the "tmp441_comp.sh" script. It will print remote temperature measurements in Celsius indefinitely, until a SIGINT occurs.

root@beaglebone:~# ./tmp441_comp.sh

Taking temperature measurements...
Remote Temp (C):  32.2750
Remote Temp (C):  32.3125
Remote Temp (C):  32.5000
