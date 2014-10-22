#!/bin/bash

#I2CSCL J1.1    P9.19
#I2CSCA J1.2    P9.20
#GND    J1.3    P9.1
#NC     J1.4    NC
#V3_3D  J1.5    P9.3

#Initialize TMP441
i2cset -y 1 0x4c 0xfc 0x1       #software reset
i2cset -y 1 0x4c 0x9 0x04       #extended temp range
i2cset -y 1 0x4c 0xA 0x1C       #resistance correction, channels enabled
i2cset -y 1 0x4c 0xB 0x7        #fastest conversion rate
#i2cset -y 1 0x4c 0xC 0x8        #beta compensation enabled, n=1.000
#i2cset -y 1 0x4c 0x21 0x7       #n-factor correction, n=1.02389
#i2cset -y 1 0x4c 0xC 0x7       #beta compensation disabled, n=1.008
#i2cset -y 1 0x4c 0x21 0x4      #n-factor correction, n=1.02162

#Take a number of measurements
echo "Taking $1 temperature measurements..."

for (( ; ; ))                   #infinite loop
#for ((i=0 ; i<$1 ; i++))       #loop to argument input
do
        #Take a measurement (remote and local sensors)
        REMOTE_HIGH=$(i2cget -y 1 0x4c 0x1 b)
        REMOTE_LOW=$(i2cget -y 1 0x4c 0x11 b)
#       LOCAL_HIGH=$(i2cget -y 1 0x4c 0x0 b)
#       LOCAL_LOW=$(i2cget -y 1 0x4c 0x10 b)
#       echo $REMOTE_HIGH $REMOTE_LOW $LOCAL_HIGH $LOCAL_LOW

        #Convert to Celsius
        let "temp = $REMOTE_LOW/16"
        REMOTE_LOW=$(echo "$temp*0.0625" | bc)
        let "temp = $REMOTE_HIGH-64"
        REMOTE_CELS=$(echo "$temp+$REMOTE_LOW " | bc)
#       let "temp = $LOCAL_LOW/16"
#       LOCAL_LOW=$(echo "$temp*0.0625" | bc)
#       let "temp = $LOCAL_HIGH-64"
#       LOCAL_CELS=$(echo "$temp+$LOCAL_LOW " | bc)

        #Output to console, log file
        echo -e "Remote Temp (C):\t$REMOTE_CELS"
#       echo -e "Local  Temp (C):\t$LOCAL_CELS\n"
done

#Calculate average temperatures
