#!/usr/bin/env bash
# Description: Containers management system


# Paths
dirname=`dirname $0`
basename=`basename $0`
filename=${basename%\.*}

APPLICATION=`echo $basename | awk -F\. '{print $1}'`
APP_DIR=`readlink -f $dirname/app`
CONFIG_DIR=`readlink -f $dirname/config`
CONFIG_FILE=$CONFIG_DIR/config.cfg
LOG_DIR=`readlink -f $dirname/logs`
LOG_FILE=$LOG_DIR/$filename.`date +%Y%m%d`.log

# Load config
[ ! -f $CONFIG_FILE ] && echo -e "${RED}ERROR: $CONFIG_FILE directory does not exist or is not readable${NORMAL}" && exit 1 || . $CONFIG_FILE &>/dev/null

# Load program functions
[ ! -d $APP_DIR ] && echo -e "${RED}ERROR: $APP_DIR directory does not exist or is not readable${NORMAL}" && exit 1
[ -z "$LOG_RETENTION_DAYS" ] && echo -e "${RED}Parameter LOG_RETENTION_DAYS has no a valid value, please set it${NORMAL}" && exit 1
for script in `find $APP_DIR -type f -name "*.sh"`; do
	. $script;
done

while true; do
	# Log management
	Clean log files
	rotate_logs

	# Create pending containers
	checkPendingContainer

	# Waiting next execution
	sleep $DAEMON
done

