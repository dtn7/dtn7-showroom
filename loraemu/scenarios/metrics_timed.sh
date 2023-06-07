#!/bin/sh

# if no arguments given exit
if [ $# -ne 2 ]; then
    echo "Usage: $0 <interval> <dir>"
    exit 1
fi

DELAY=$1
TARGET_DIR=$2
TIME=0

echo "# time\tcreated\tdelivered\tdelivered/created"

# loop while file does not exist
while [ ! -f $TARGET_DIR/stop.txt ]; do
    sleep $DELAY
    TIME=$(($TIME + $DELAY))

    RX=$(rg --no-filename 'Received bundle for local delivery' $TARGET_DIR/*/*.txt | wc -l)
	  TX=$(rg --no-filename 'Transmission of bundle requested' $TARGET_DIR/*/*.txt | wc -l)

    # check if TX is zero
    if [ $TX -eq 0 ]; then
        RATE=0
    else
        RATE=$(echo "scale=4; x=$RX / $TX ; if(x<1) print 0; x" | bc)
    fi

    echo "$TIME.0000 $TX $RX $RATE"
done