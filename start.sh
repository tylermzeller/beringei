#!/bin/bash

# Create the configuration for beringei
echo "[UP] Creating Beringie Config"
./beringei/tools/beringei_configuration_generator \
  --host_names $(hostname) \
  --file_path $WORKDIR/beringei.json

echo "[UP] Starting Beringie Main"
./beringei/service/beringei_main \
  -beringei_configuration_path $WORKDIR/beringei.json \
  -create_directories \
  -sleep_between_bucket_finalization_secs 60 \
  -allowed_timestamp_behind 300 \
  -bucket_size 600 \
  -buckets 144 \
  -mintimestampdelta 1 \
  -v=2 &


beringei_main_pid=$!
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start beringei_main: $status"
  exit $status
fi

echo "[UP] Starting Beringie HTTP Server"
./beringei/tools/plain_text_service/beringei_plain_text_service \
  -beringei_configuration_path $WORKDIR/beringei.json \
  -http_port 9990 \
  -ip $(hostname) \
  -threads 0 &

server_pid=$!
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start beringei_plain_text_service: $status"
  exit $status
fi

while sleep 60; do
  ps aux |grep beringei_main |grep -q -v grep
  PROCESS_1_STATUS=$?
  ps aux |grep beringei_plain_text_service |grep -q -v grep
  PROCESS_2_STATUS=$?
  # If the greps above find anything, they will exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 ]; then
    echo "One of the processes has already exited."
    exit -1
  fi
done
