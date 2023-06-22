#!/bin/bash

SEND_MSG=${SEND_MSG:-"Lorem ipsum dolor sit amet, consectetuer"}
SEND_WAIT=${SEND_WAIT:-"60"}
MSG_COUNT=${MSG_COUNT:-"5"}

for (( c=1; c<=$MSG_COUNT; c++ ))
do
  echo ${SEND_MSG} | "$DTND/dtnsend" -p 3000 --receiver dtn://node5/incoming;
  echo ${SEND_MSG} | "$DTND/dtnsend" -p 3004 --receiver dtn://node1/incoming;
  sleep $SEND_WAIT
done