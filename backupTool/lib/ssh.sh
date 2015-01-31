#!/bin/bash

function check_server_connection {
  local USER=$1
  local SERVER=$2
  local EXECUTION_COMMAND="ssh -l $USER $SSH_OPTIONS $SERVER hostname"

  info "Checking if server $SERVER is available..."
  info "Executing command: \"$EXECUTION_COMMAND\" on server $SERVER"
  EXECUTION_RESULT=`$EXECUTION_COMMAND 2>/dev/null`
  return $?
}

function execute_remote_command {
  local USER=$1
  local SERVER=$3
  local OTHER_SSH_OPTIONS="${@:4}"

  get_object_parameter $SERVER ip $SERVERS_CONFIG
  [ ! -z $VALUE ] && SERVER=$VALUE

  local EXECUTION_COMMAND="ssh -l $USER $SSH_OPTIONS $OTHER_SSH_OPTIONS $SERVER $2"

  # Checking if server is available...
  check_server_connection $USER $SERVER
  [ $? -ne 0 ] && error "Server $SERVER is not available, skipping remote command execution..." && return 255

  info "Executing command: \"$EXECUTION_COMMAND\" on server $SERVER"

  echo "$SSH_OPTIONS $OTHER_SSH_OPTIONS" | grep " \-f " >/dev/null 
  [ $? -eq 0 ] && $EXECUTION_COMMAND 2>&1 || EXECUTION_RESULT=`$EXECUTION_COMMAND 2>&1`

  EXECUTION_RESULT_CODE=$?
  if [ $EXECUTION_RESULT_CODE -eq 0 ]; then
     info "execute_remote_command function: Remote command successfully executed on server $SERVER"
     info "execute_remote_command function: Command output was: $EXECUTION_RESULT"
  else
     info "execute_remote_command function: Could not execute remote command on server $SERVER"
     info "Error was: $EXECUTION_RESULT"
  fi
  return $EXECUTION_RESULT_CODE 
}
