#!/bin/bash

function log {
  current_time=`date "+%d/%m/%Y %H:%M:%S"`
  echo -e "[$current_time] $@" >> $LOG_FILE
  echo -e "[$current_time] $@"
}

function debug {
  while read -r line; do
     log "[DEBUG] $line"
  done <<< "$@"
}

function info {
  while read -r line; do
     log "[INFO] $line"
  done <<< "$@"
}

function warning {
  while read -r line; do
     log "[WARNING] ${line}"
  done <<< "$@"
}

function error {
  while read -r line; do
     log "[ERROR] $line"
  done <<< "$@"
}

function compress_old_logs {
  LOG_COMPRESSION_CMD="find $LOG_DIR -name "$filename.*.log" -type f -mtime +1 -exec bzip2 -v {} \;"
  info "Compressing old log files. Executing command: $LOG_COMPRESSION_CMD"
  LOG_COMPRESSION_OUTPUT=`eval $LOG_COMPRESSION_CMD 2>&1`
  if [ -z "$LOG_COMPRESSION_OUTPUT" ]; then 
     info "0 log files compressed" 
  else 
     info "Log compression completed. Result was:" 
     info "$LOG_COMPRESSION_OUTPUT"
  fi
}

function delete_old_logs {
  LOG_DELETION_CMD="find $LOG_DIR -name "$filename.*.log" -type f -mtime +$LOG_RETENTION_DAYS -exec rm -vf {} \;"
  info "Deleting old log files. Executing command: $LOG_DELETION_CMD"
  LOG_DELETION_OUTPUT=`eval $LOG_DELETION_CMD 2>&1`
  if [ -z "$LOG_DELETION_OUTPUT" ]; then
     info "0 old log files deleted"
  else
     info "Old log deletion completed. Result was:" 
     info "$LOG_DELETION_OUTPUT"
  fi
}
