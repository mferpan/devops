#!/usr/bin/env bash
# Description: Manage log files

function log {
  current_time=`date`
  echo -e "[$current_time] $@" >> $LOG
  echo -e "[$current_time] $@"
}

function info {
  while read -r line; do
     log "${GREEN}[INFO] $line${NORMAL}"
  done <<< "$@"
}

function warning {
  while read -r line; do
     log "${ORANGE}[WARNING] $line${RED}"
  done <<< "$@"
}

function error {
  while read -r line; do
     log "${RED}[ERROR] $line${NORMAL}"
  done <<< "$@"
}

function compress_old_logs {
  LOG_COMPRESSION_CMD="find ${LOG_DIR} -name "*.log" -type f -mtime +1 -exec bzip2 -v {} \;"
  info " __ Compressing old log files. Executing command: $LOG_COMPRESSION_CMD"
  LOG_COMPRESSION_OUTPUT=`eval $LOG_COMPRESSION_CMD 2>&1`
  if [ -z "$LOG_COMPRESSION_OUTPUT" ]; then 
     info " __ 0 log files compressed" 
  else 
     info " __ Log compression completed. Result was:" 
     info " __ ${LOG_COMPRESSION_OUTPUT}"
  fi
}

function delete_old_logs {
  LOG_DELETION_CMD="find ${LOG_DIR} -name "*.log.bz2" -type f -mtime +$LOG_RETENTION_DAYS -delete"
  info " __ Deleting old log files. Executing command: $LOG_DELETION_CMD"
  LOG_DELETION_OUTPUT=`eval $LOG_DELETION_CMD 2>&1`
  if [ -z "$LOG_DELETION_OUTPUT" ]; then
     info " __ 0 old log files deleted"
  else
     info " __ Old log deletion completed. Result was:" 
     info " __ ${LOG_DELETION_OUTPUT}"
  fi
}

function rotate_logs {
  compress_old_logs
  delete_old_logs
}