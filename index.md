---
layout: project
title: rtdc
subtitle: A daughter card for monitoring the temperature of a remote thermal diode.
---

<img src="http://niftyhedgehog.com/rtdc/images/rtdc-pcb-assembled.jpg">

## Overview
Many integrated circuits have thermal specification requirements, which include temperature guidelines that must *not* be exceeded in order to prevent damage from occurring on the device or system. Managing the junction temperature is imperative to meeting the lifetime, reliability, and performance specifications of the device. For active thermal management techniques in processors, an accurate reading of the junction temperature must be obtained to allow control software to respond effectively. 

One way to do this is by using diode-connected transistors built into the processor chips. Temperature measurement is performed by measuring the change in forward bias voltage of a diode when two different currents are forced through the junction. This solution is typically low-cost, reduces component count, overcomes thermal gradient and placement issues encountered when trying to place external sensors, and is accurate to ±1°C.

The Remote Temperature Daughter Card (RTDC) uses a [TMP441](http://www.ti.com/lit/ds/symlink/tmp441.pdf) to monitor the temperature of a remote thermal diode. By using a sequential current excitation, the RTDC can extract a differential VBE on the remote transistor and calculate its junction temperature. The TMP441 has features to improve measurement accuracy such as beta compensation, series resistance cancellation, and ideality factor correction. Communication is done over an I2C bus, with the RTDC having breakouts for a Power Measurement Daughter Card (PMDC) or any other I2C master such as a BeagleBone Black.

This repository includes:

* Altium library, schematic, and board files
* PCB gerbers and drill files
* Bill of materials
* Bash shell scripts
* C code for integrating with the MSP430-based PMDC
* Misc. Documentation


## Hardware

<img src="http://niftyhedgehog.com/rtdc/images/rtdc-oshpark-top.png" width="30%">
<img src="http://niftyhedgehog.com/rtdc/images/rtdc-oshpark-bottom.png" width="30%">
<img src="http://niftyhedgehog.com/rtdc/images/rtdc-3d-render.jpg" width="30%">

The TMP441 on the RTDC interfaces with a remote thermal diode via two connections: *DXP* and *DXN*. DXP connects to the thermal diode's anode and sources the diode bias current. DXN sinks the bias current and biases the cathode. Either NPN- or PNP-type transistors can be used, as long as the base-emitter junction is used as the remote temperature sense. The TMP441 has a temperature range of –40°C to +125°C, but can be configured to use an extended range from –55°C to +150°C. Remote accuracy is ±1°C for multiple IC manufacturers, with no calibration needed.

The RTDC can be used in GND collector-connected transistor configuration and also diode-connected transistor configuration. Diode-connected transistor configuration provides better settling time, while GND collector-connected transistor configuration provides better series resistance cancellation.

Errors in remote temperature sensor readings are typically the consequence of the ideality factor and current excitation. The TMP441 uses 6uA for I_low and 120uA for I_high. It also features automatic beta compensation (correction), series resistance cancellation, and programmable non-ideality factor. 
To reduce noise and series resistance, the PCB layout keeps diode traces short without using vias or layer changes. Ground guard traces are also used, and a 330pF filter capacitor between DXP and DXN helps to minimize the effects of noise.

The initial prototype is available for purchase on [OSH Park](https://oshpark.com/shared_projects/W2ilfkCv) for a whopping $1.65.

### Usage
The driving use case for the RTDC was to measure the junction temperature of the AM437x processor, which contains special temperature monitoring hardware. The AM437x contains a GND collector-connected PNP transistor, which connects to a thermal diode to estimate junction temperature. The junction temperature can be monitored remotely with an RTDC and BeagleBone Black, serving as I2C master and host computer. 

The RTDC plugs directly into header pins on each test platform. The RTDC needs a 4-wire cable to interface with the BeagleBone Black. This cable connects the RTDC's 3.3V, GND, and I2C signals to the BeagleBone's P9 expansion header. Be sure to align the polarity of the TEMP_DIODE signals with the RTDC's J3 receptacle; TEMP_DIODE_P is pin 1.

| Signal | RTDC |  BBB  |
|:------:|:----:|:-----:|
| I2CSCL | J1.1 | P9.19 |
| I2CSCA | J1.2 | P9.20 |
| GND    | J1.3 | P9.1  |
| NC     | J1.4 | NC    |
| V3_3D  | J1.5 | P9.3  |

It should look something like this:

<img src="http://niftyhedgehog.com/rtdc/images/rtdc-am437x-gp-evm.jpg">


## Software
The RTDC software is a Bash script, which configures the TMP441 and reads/converts temperature data streamed over the I2C bus. It also enables the beta compensation, series resistance cancellation, and ideality factor correction features to reduce error. 

```bash
...
#Take a measurement (store high and low bytes separately for endian correction)
REMOTE_HIGH=$(i2cget -y 1 0x4c 0x1 b)
REMOTE_LOW=$(i2cget -y 1 0x4c 0x11 b)
...
#Convert to Celsius
let "temp = $REMOTE_LOW/16"
REMOTE_LOW=$(echo "$temp*0.0625" | bc)
let "temp = $REMOTE_HIGH-64"
REMOTE_CELS=$(echo "$temp+$REMOTE_LOW " | bc)
...
#Output to console
echo -e "Remote Temp (C):\t$REMOTE_CELS"
```

The forward current gain (beta) of a transistor is not a constant over all operating conditions, but varies over temperature. If the transistor has a large variation in beta as a function of Ic, the temperature reading can be inaccurate due to beta-induced error. To manage this increasing temperature measurement error, the TMP441 controls the collector current instead of the emitter current. It can automatically detect and choose the correct range depending on the beta factor of the external transistor. This auto-ranging is performed at the beginning of each temperature conversion in order to correct for changes in the beta factor as a result of temperature variation.

Series resistance is another parameter that affects temperature measurement accuracy, causing the sensor to report temperature higher than the actual temperature of the thermal diode. It is a constant offset for all temperatures. A total of up to 1k-ohm of series line resistance is cancelled by the TMP441, eliminating the nee for additional characterization and temperature offset correction. 

The ideality factor is a measured characteristic of a remote temperature sensor diode as compared to an ideal diode. It approaches a value of 1.0 when the carrier diffusion dominates the current flow, and approaches 2.0 when the recombination current dominates the current flow. The term is constant on any particular device, though it can vary among individual devices. The manufacturer of the IC will specify the ideality factor parameter in the datasheet. When the ideality factor is known, the temperature measurement can be compensated mathematically.


### Usage
Boot a Debian Linux image (native support for [bc](https://www.gnu.org/software/bc/manual/html_mono/bc.html)) on the BeagleBone Black and run the "tmp441_comp.sh" script. It will print remote temperature measurements in Celsius indefinitely, until a SIGINT occurs.

```bash
root@beaglebone:~# ./tmp441_comp.sh

Taking temperature measurements...
Remote Temp (C):  32.2750
Remote Temp (C):  32.3125
Remote Temp (C):  32.5000
```
