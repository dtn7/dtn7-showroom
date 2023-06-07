#!/bin/bash

SENT=$(rg --no-filename "Transmission of bundle requested" $1/cmdlogs/*.txt | wc -l)
RECEIVED=$(rg --no-filename "Received bundle for local delivery" $1/cmdlogs/*.txt | wc -l)

if [ $SENT -eq $RECEIVED ] ; then
    echo "EXPERIMENT RESULT: Success | tx: $SENT, rx: $RECEIVED"
else
    echo "EXPERIMENT RESULT: Failed | tx: $SENT, rx: $RECEIVED"
    exit 1
fi