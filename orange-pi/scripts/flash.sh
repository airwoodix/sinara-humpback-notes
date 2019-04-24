#!/bin/bash

GPIO_CTRL=0
PIN_RESET=19  # PA19
PIN_DONE=199  # PG07
SPI_DEVICE=/dev/spidev2.0

# reset fpga
gpioset $GPIO_CTRL $PIN_RESET=0
sleep 0.1

# create padded bitstream
# https://superuser.com/a/275055
image=$(mktemp)
dd if=/dev/zero ibs=1 count=$((1024*1024)) status=none | tr '\0' '\377' > $image
dd if=$1 of="$image" conv=notrunc status=none

# write bitstream to flash
flashrom -p linux_spi:dev="$SPI_DEVICE",spispeed=100 -w $image
sleep 0.1

# load bitstream
gpioset $GPIO_CTRL $PIN_RESET=1
sleep 0.2

# check status
if [ $(gpioget $GPIO_CTRL $PIN_DONE) -eq 1 ]; then
    echo "DONE"
else
    echo "Warning: CDONE is low"
fi

# cleanup
rm -f $image
