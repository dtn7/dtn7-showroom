#!/bin/bash

SEND_MSG=${SEND_MSG:-"hello world"}
SEND_NODE=${SEND_NODE:-"0_0"}
RECEIVE_NODE=${RECEIVE_NODE:-"5_5"}
MSG_COUNT=${MSG_COUNT:-"1"}
SEND_WAIT=${SEND_WAIT:-"0"}

COORDS=(${SEND_NODE//_/ })

# Convert xy to port of dtnd. We know that ports are ascending from 3000 (0x0), so we can
# calculate the port of the sending node.
PORT=$(echo "scale=4; 3000 + ${COORDS[0]} + ${COORDS[1]} * 6" | bc -l)

echo "x=${COORDS[0]} y=${COORDS[1]} port=$PORT"

for (( c=1; c<=$MSG_COUNT; c++ ))
do
  echo ${SEND_MSG} | "$DTND/dtnsend" -p $PORT --receiver dtn://node$RECEIVE_NODE/incoming;
  sleep ${SEND_WAIT}
done