#!/bin/bash
# script to log basic information for daily run validation

TIMESTAMP=$(date +%Y-%m-%d %H:%M:%S %Z%z)
LOG_FILE="/home/xiekang.zhang/daily_run.log"

PASSWORD=$(secret_key_value)

echo "-----------------------------------------------------------" >> "$LOG_FILE"
echo "Daily run started at: $TIMESTAMP" >> "$LOG_FILE"
echo "and used password: $PASSWORD" >> "$LOG_FILE"
echo "Script executed successfully. " >> "$LOG_FILE"
echo "-----------------------------------------------------------" >> "$LOG_FILE"

exit 0