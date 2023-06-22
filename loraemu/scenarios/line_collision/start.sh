#!/bin/bash

INTERVALS=("10s" "15s" "20s" "15s" "10s")
STRATEGY=${STRATEGY:-"quadrant"}
STRATEGY_ARGS=${STRATEGY_ARGS:-""}

if [ "$STRATEGY_ARGS" = "" ]; then
  STRATEGY_ARGS="SEND_INTERVAL=${INTERVALS[$1]}"
else
  STRATEGY_ARGS="$STRATEGY_ARGS,SEND_INTERVAL=${INTERVALS[$1]}"
fi

PORT=$(($1 + 3000))
NODE_ID=$2

echo $NODE_ID $STRATEGY $STRATEGY_ARGS $PORT

$LORA_ECLA/loclad -d --ecla_addr 127.0.0.1:$PORT --ecla_module=LoRa --lora_agent=websocket --lora_arg=127.0.0.1$3:$NODE_ID --strategy_name=$STRATEGY \
                  --strategy_config=$STRATEGY_ARGS --dtnd="$DTND/dtnd" \
                  --dtnd_args="-w $PORT -r epidemic -n $NODE_ID --ecla -e incoming -e emergency -d -i 400h"