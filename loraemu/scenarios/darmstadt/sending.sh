#!/bin/bash

SEND_MSG=${SEND_MSG:-"hello world"}
MSG_COUNT=${MSG_COUNT:-"1"}
SEND_WAIT=${SEND_WAIT:-"0"}

ALL_NODES=("car1" "car2" "emergencity" "park" "innercity1" "innercity2" "north1" "north2" "north3" "north4" "south1" "south2" "south3" "person1" "person2" "person3" "person4")
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