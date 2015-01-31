#!/bin/bash

function check_requirements {
  # Check if main config file exists and load it
  [ ! -e $CONFIG_FILE ] && error "Configuration file $CONFIG_FILE does not exist or is not readable" && exit 1
  . $CONFIG_FILE

  [ -z "$USER_COMMAND" ] || [ -z "$USER_OBJECTS" ] && error "Missing parameters..." && exit 1
  [ -z $ENVIRONMENT ] && error "ENVIRONMENT variable was found" && exit 1
  [ -z $EXECUTION_USERS ] && error "No EXECUTION_USERS variable was found in config file $CONFIG_FILE" && exit 1
  local USER_FOUND=FALSE
  for user in `echo $EXECUTION_USERS | sed 's/,/ /g'`; do
      [ `whoami` = "$user" ] || [ `who am i | awk '{print $1}'` = "$user" ] && USER_FOUND=TRUE && break
  done
  [ $USER_FOUND = "FALSE" ] && [ "$USER_COMMAND" != "backup" ] && error "This tool should be executed with one of these users: $EXECUTION_USERS user. Current user is `whoami`" && exit 1

  SERVERS_CONFIG=$CONFIG_DIR/$ENVIRONMENT/servers.config
  [ ! -e $SERVERS_CONFIG ] && error "Configuration file $SERVER_CONFIG does not exist or is not readable" && exit 1
}

function load_objects_from_config {
  local OBJECTS_AVAILABLE=`grep -E "^\[(.*)\]" $OBJECTS_CONFIG | sed 's/^\[//g' | sed 's/\]//g'`
  local i=0
  unset OBJECTS_AVAILABLE_ARRAY

  for object in $OBJECTS_AVAILABLE; do
      OBJECTS_AVAILABLE_ARRAY[$i]=$object
      i=$((i+1))
  done
}

function get_object_parameter {
  local OBJECT=$1
  local PARAMETER=$2
  local CONFIG_FILE="$3"
  unset VALUE

  OBJECT_FIRSTLINE_DEFINITION=`grep -nE "^\[$OBJECT\]" "$CONFIG_FILE" | tail -1 | awk -F: '{print $1}'`
  OBJECT_NUMLINES_DEFINITION=`sed "1,${OBJECT_FIRSTLINE_DEFINITION}d" "$CONFIG_FILE" | grep -nE "^\[.*\]" | head -1 | awk -F: '{print $1}'`
  CONFIG_LINES=`wc -l "$CONFIG_FILE" | awk '{print $1}'`

  [ -z $OBJECT_NUMLINES_DEFINITION ] && OBJECT_NUMLINES_DEFINITION=$((CONFIG_LINES-OBJECT_FIRSTLINE_DEFINITION))

  local OBJECT_PARAMS_TMP=/tmp/$basename.$$.$OBJECT.$PARAMETER.parameter
  sed -n "${OBJECT_FIRSTLINE_DEFINITION},$((OBJECT_FIRSTLINE_DEFINITION+OBJECT_NUMLINES_DEFINITION))p;$((OBJECT_FIRSTLINE_DEFINITION+OBJECT_NUMLINES_DEFINITION))q" "$CONFIG_FILE" | grep -vE "^\[.*\]" | sed "s/^$PARAMETER=\"/VALUE=\"/g" | sed "s/^$PARAMETER=/VALUE=/g" > $OBJECT_PARAMS_TMP
  . $OBJECT_PARAMS_TMP
  rm -f $OBJECT_PARAMS_TMP
}

function get_all_servers {
  local AUX_CONFIG=$OBJECTS_CONFIG
  OBJECTS_CONFIG=$SERVERS_CONFIG

  load_objects_from_config 

  OBJECTS_CONFIG=$AUX_CONFIG

  for serverIndex in ${!OBJECTS_AVAILABLE_ARRAY[*]}; do   
      EXECUTION_SERVERS_ARRAY[$serverIndex]=${OBJECTS_AVAILABLE_ARRAY[$serverIndex]}
  done
}
