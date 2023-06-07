#!/bin/sh

# if no arguments given exit
if [ $# -ne 2 ]; then
    echo "Usage: $0 <interval> <dir>"
    exit 1
fi

DELAY=$1
TARGET_DIR=$2
TIME=0

echo "time;%cpu;%mem"

# loop while file does not exist
while [ ! -f $TARGET_DIR/stop.txt ]; do
    sleep $DELAY
    TIME=$(($TIME + $DELAY))

    CPU=$(ps -o %cpu,command | grep -E "/(dtnd|emu)" | awk '{for(i=1; i<=NF; i++){if($i~/^[0-9]*\.?[0-9]+$/) {sum+=$i; break;}}}; END{print sum}')
    MEM=$(ps -o %mem,command | grep -E "/(dtnd|emu)" | awk '{for(i=1; i<=NF; i++){if($i~/^[0-9]*\.?[0-9]+$/) {sum+=$i; break;}}}; END{print sum}')

    echo "$TIME.0000;$CPU;$MEM"
done