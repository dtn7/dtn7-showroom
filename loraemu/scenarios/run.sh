#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <scenario_path> <timeout>"
    exit 1
fi

# emu and log-inspect binaries
EMU=${EMU:-"loraemu"}
LOG_INSPECT=${LOG_INSPECT:-"loraemu-log-inspect"}
RUN_FOLDER=${RUN_FOLDER:-"./run_result"}
EMU_FLAGS=${EMU_FLAGS:-""}

# scenario and timeout params
SCENARIO=$1
TIMEOUT=${2:-"15s"}

# paths
LOG_FILE=$RUN_FOLDER/logs.txt

# clean and setup run result folder
rm -r $RUN_FOLDER/*
mkdir $RUN_FOLDER

# export dtnd and loclad path
export DTND=/usr/local/bin
export LORA_ECLA=/usr/local/bin

echo "Running '$SCENARIO' with timeout $TIMEOUT"

# run pre script if exists and check return code
if command -v ./$SCENARIO/pre.sh &> /dev/null
then
  ./$SCENARIO/pre.sh $RUN_FOLDER
  if [ "$?" -ne "0" ]; then
    echo "failure in pre-script: $?"
    exit $?
  fi
fi

# run timed dtnd metric collector
./metrics_timed.sh 1 $RUN_FOLDER >> $RUN_FOLDER/dtnd_timed_metrics.txt &
METRICS_TIMED_PID=$!

# run timed cpu usage metric collector
./resources_timed.sh 1 $RUN_FOLDER >> $RUN_FOLDER/resources_metrics.txt &
RESOURCES_TIMED_PID=$!

# start the emulator with the scenario
date +%s >> $RUN_FOLDER/start.txt
START=$(date +%s)

$EMU $EMU_FLAGS --config="./$SCENARIO/scenario.json" --log=$LOG_FILE --wait_for=all --timeout=$TIMEOUT

date +%s >> $RUN_FOLDER/stop.txt
STOP=$(date +%s)
ELAPSED=$((STOP - START))

# kill collector
kill $METRICS_TIMED_PID
kill $RESOURCES_TIMED_PID

# kill residual process if something didn't shutdown correctly
killall loclad
killall dtnd

# calc total airtime
TOTAL_AIRTIME=$($LOG_INSPECT -input $LOG_FILE -expr "event == 'NodeSending' ? data_airtime : 0.0" -output sum)
echo "total airtime: $TOTAL_AIRTIME"
echo "$TOTAL_AIRTIME" >> $RUN_FOLDER/total_airtime.txt

# split node ids
IFS=';' read -r -a NODE_IDS <<< "$($LOG_INSPECT/log-inspect -input $LOG_FILE -expr "event == 'NodeAdded' ? nodeId : ''" -output concat)"

# fetch metrics of each node
echo "node_id;total_airtime;airtime_percent;sent;received;collision" >> $RUN_FOLDER/lora_node_stats.csv
for element in "${NODE_IDS[@]}"
do
    airtime=$($LOG_INSPECT/log-inspect -input $LOG_FILE -expr "event == 'NodeSending' && nodeId == '$element' ? data_airtime : 0.0" -output sum)
    echo "$element;$($LOG_INSPECT/log-inspect -input $LOG_FILE -expr "event == 'NodeSending' && nodeId == '$element' ? data_airtime : 0.0" -output sum);$(echo "scale=4; $airtime / 1000 / $ELAPSED" | bc -l);$($LOG_INSPECT/log-inspect -input $LOG_FILE -expr "nodeId == '$element' && event == 'NodeSending'" -output count);$($LOG_INSPECT/log-inspect -input $LOG_FILE -expr "nodeId == '$element' && event == 'NodeReceived'" -output count);$($LOG_INSPECT/log-inspect -input $LOG_FILE -expr "nodeId == '$element' && event == 'NodeCollision'" -output count)" >> $RUN_FOLDER/lora_node_stats.csv
done

# collect dtnd metrics
./metrics.sh $RUN_FOLDER >> $RUN_FOLDER/dtnd_metrics.txt

# collect latency
./latency.sh $RUN_FOLDER

# run post script if exists and check return code
if command -v ./$SCENARIO/post.sh &> /dev/null
then
  ./$SCENARIO/post.sh $RUN_FOLDER
  if [ "$?" -ne "0" ]; then
    echo "failure in post-script: $?"
    exit $?
  fi
fi