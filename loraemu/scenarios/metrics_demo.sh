#!/bin/bash

# if no arguments given exit
if [ $# -eq 0 ]; then
    echo "Usage: $0 <run_result_basepath>"
    exit 1
fi

BASEPATH=$1

START=$(cat $BASEPATH/start.txt)
END=$(date +%s)
# delta of START and END is the duration of the experiment
DURATION=$(($END - $START))
echo sim_time: $DURATION
CREATED=$(rg --no-filename "Transmission of bundle requested" $BASEPATH/*/*.txt | wc -l)
echo created: $CREATED
TRANSFERRED=$(rg --no-filename "Sending bundle succeeded" $BASEPATH/*/*.txt | wc -l)
echo transferred: $TRANSFERRED
RELAYED=$(rg --no-filename "Received new bundle" $BASEPATH/*/*.txt | wc -l)
echo relayed: $RELAYED
ABORTED=$(rg --no-filename "Sending bundle .+ failed" $BASEPATH/*/*.txt | wc -l)
DROPPED=$(rg --no-filename "Dropping bundle" $BASEPATH/*/*.txt | wc -l)
REMOVED=$(rg --no-filename "Removing bundle" $BASEPATH/*/*.txt | wc -l)
REFUSED=$(rg --no-filename "refusing bundle" $BASEPATH/*/*.txt | wc -l)
DELIVERED2=$(rg --no-filename "Received bundle for local delivery" $BASEPATH/*/*.txt | awk '{print $10}' | sort -u | wc -l)
DELIVERED=$(rg --no-filename "Received bundle for local delivery" $BASEPATH/*/*.txt | wc -l)
echo delivered: $DELIVERED
echo delivered unique: $DELIVERED2
DELIVERY_PROBABILITY=$(echo "scale=4; x=$DELIVERED / $CREATED ; if(x<1) print 0; x" | bc)
echo delivery_prob: $DELIVERY_PROBABILITY
#echo overhead_ratio: $(echo "scale=4; x=$(($RELAYED - $DELIVERED)) / $DELIVERED ; if(x<1) print 0; x" | bc)
DUP_RATE=$(echo "scale=4; x=$REFUSED / $TRANSFERRED ; if(x<1) print 0; x" | bc)
#latency_avg: 276.4796
#latency_med: 204.6500
#hopcount_avg: 3.0120
#hopcount_med: 3
#buffertime_avg: NaN
#buffertime_med: NaN
#rtt_avg: NaN
#rtt_med: NaN