#!/bin/bash

SEND_MSG=${SEND_MSG:-"hello world"}
MSG_COUNT=${MSG_COUNT:-"1"}
SEND_WAIT=${SEND_WAIT:-"0"}

ALL_NODES=("auto1" "auto2" "emergencity" "herrngarten" "innercity1" "innercity2" "nord1" "nord2" "nord3" "nord4" "sd1" "sd2" "sd3" "fugnger1" "fugnger2" "fugnger3" "fugnger4")
NUM_NODES=${#ALL_NODES[@]}

echo $NUM_NODES

for (( c=1; c<=$MSG_COUNT; c++ ))
do
  SELECTED=${ALL_NODES[ $RANDOM % ${#ALL_NODES[@]}]}
  PORT=$((3000 + $RANDOM % $NUM_NODES))
  echo $SELECTED $PORT
  echo ${SEND_MSG} | "$DTND/dtnsend" -p $PORT --receiver dtn://$SELECTED/incoming;
  sleep ${SEND_WAIT}
done