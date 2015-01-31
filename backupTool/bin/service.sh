#!/usr/bin/env bash
#
# Cron Usage
# 0 * * * * /opt/systems/services/bin/emergya.services.sh backup all &> /dev/null

# Vars
DATE=`date +%Y%m%d`
dirname=`dirname $0`
basename=`basename $0`
filename=${basename%\.*}

USER_COMMAND=`echo $1 | tr '[:upper:]' '[:lower:]'`
USER_OBJECTS=$2  # Servers list

# Validation Area
[ ! -L $dirname/$basename ] && echo -e "[ERROR]: This script must be executed using environment symlinks in `readlink -m $dirname`" && exit 1
[ ! -d $LIB_DIR ] && echo -e "[ERROR]: $LIB_DIR directory does not exist or is not readable" && exit 1
[ ! -d $LOG_DIR ] && echo -e "[ERROR]: $LOG_DIR directory does not exist or is not readable" && exit 1
[ ! -d $CONFIG_DIR ] && echo -e "[ERROR]: $CONFIG_DIR directory does not exist or is not readable" && exit 1
TARGET_SERVERS=$USER_OBJECTS

ENVIRONMENT=`echo $basename | awk -F\. '{print $1}'`
LIB_DIR=`readlink -f $dirname/../lib`
CONFIG_DIR=`readlink -f $dirname/../config`
CONFIG_FILE=$CONFIG_DIR/$ENVIRONMENT/main.config
LOG_DIR=`readlink -f $dirname/../logs`
[ "$USER_COMMAND" = "backup" ] && LOG_FILE=$LOG_DIR/$filename.$USER_COMMAND.$DATE.log

# Load config
. $CONFIG_FILE &>/dev/null
for script in `find $LIB_DIR -type f -name "*.sh"`; do . $script; done
[ -z "$LOG_RETENTION_DAYS" ] && echo -e "Parameter LOG_RETENTION_DAYS has no a valid value, please set it" && exit 1

# Clean logs
#compress_old_logs
#delete_old_logs

# Checking Requirements
check_requirements

info "Executing command Backup..."
if [ ! -z $TARGET_SERVERS ] && [ $TARGET_SERVERS != "all" ]; then
   i=0
   for target_server in `echo $TARGET_SERVERS | sed 's/,/ /g'`; do
       TARGET_SERVERS_ARRAY[$i]=$target_server
       i=$((i+1))
   done
   info "\tServers: ${TARGET_SERVERS_ARRAY[*]}"
else
   info "\tServers: not specified, so getting server list from configuration"
   get_all_servers
fi

# Generate Array
for ((i=0; i<${#EXECUTION_SERVERS_ARRAY[*]}; i++)); do
   TARGET_SERVERS_ARRAY[$i]=${EXECUTION_SERVERS_ARRAY[$i]}
done

# Read Array and execute Backup
for execution_server in ${TARGET_SERVERS_ARRAY[*]}; do 
   filesystem_backup $execution_server
done

exit 0
