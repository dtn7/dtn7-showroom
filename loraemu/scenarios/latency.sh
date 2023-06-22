#!/bin/bash

rm $1/latency.txt
rm $1/latency_avg.txt

# extract send and receives
rg --no-filename "Transmission of bundle requested" $1/cmdlogs/*.txt >> $1/sent.txt
rg --no-filename "Received bundle for local deliver" $1/cmdlogs/*.txt >> $1/received.txt

# split sends
IFS=$'\n' read -d '' -r -a LINES < $1/sent.txt
REGEX='(.*) INFO  .*: (.+)$'

SUM=0
COUNT=0

echo "id;start;stop;elapsed" >> $1/latency.txt

# iterate over sends
for line in "${LINES[@]}"
do
  [[ $line =~ $REGEX ]]

  # parser start date
  if [ "$(uname)" == "Darwin" ]; then
    START=$(date -j -u -f " %Y-%m-%dT%H:%M:%S" " ${BASH_REMATCH[1]}" "+%s")
  else
    START=$(date --date="${BASH_REMATCH[1]}" "+%s") # TODO: test on linux. Might be wrong
  fi

  # get node id
  ID=${BASH_REMATCH[2]}

  # search for stop
  STOP_LINE=$(rg --no-filename "Received bundle for local delivery: ${ID}" $1/received.txt)

  # check if it was found
  if [[ $STOP_LINE =~ $REGEX ]]; then
    if [ "$(uname)" == "Darwin" ]; then
      STOP=$(date -j -u -f " %Y-%m-%dT%H:%M:%S" " ${BASH_REMATCH[1]}" "+%s")
    else
      STOP=$(date --date="${BASH_REMATCH[1]}" "+%s") # TODO: test on linux. Might be wrong
    fi

    ELAPSED=$(($STOP - $START))
    SUM=$(($SUM + $ELAPSED))
    COUNT=$(($COUNT + 1))

    echo "${BASH_REMATCH[2]};$START;$STOP;$ELAPSED" >> $1/latency.txt
  fi
done

echo $(echo "scale=4; $SUM / $COUNT" | bc -l) >> $1/latency_avg.txt
