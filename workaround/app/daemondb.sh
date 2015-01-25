#!/usr/bin/env bash
# Description: Manage database opereations


function reviewTasks () {
	info ""
}


function generateContainer () {
	$LXC_CREATE --template $1 --name=$2 --lxcpath=$LXC_ROOT/
	[ $? -eq 0 ] && return 0 || return 1
}


function createContainer () {
	local PENDING_IDS=$1
	local MAC="$( for j in {1..12} ; do echo -n ${HEXCHARS:$(( $RANDOM % 16 )):1} ; done | sed -e 's/\(..\)/-\1/g' )"
	MAC=`echo $MAC |sed -e 's/^-//g'`

	for i in $PENDING_IDS; do
		SQL_GET_PENDING="SELECT user_id,container_type,template FROM $MYSQL_DATABASE.pending_containers WHERE id=$i;"
	    local PENDING=`echo "$SQL_GET_PENDING" | $MYSQL_CMD`

	    local USER_ID=`echo $PENDING | awk '{print $1}'`
	    local CONTAINER_TYPE=`echo $PENDING | awk '{print $2}'`
		local TEMPLATE=`echo $PENDING | awk '{print $3}'`

		info "Pending container \"$i\" generation started"

		info "Step 1: Create Storage"
		createStorage $USER_ID $CONTAINER_TYPE
		[ $? -ne 0 ] && error "Storage generation FAILED" && exit 1

		info "Step 2: Container Installation"
		mountPartition $USER_ID
		generateContainer $TEMPLATE $USER_ID
		[ $? -ne 0 ] && error "Storage generation FAILED" && exit 1

		info "Determine new IP Address"
		getIP

		# Insert in containers table
		SQL_UPDATE_GENERATED="INSERT INTO $MYSQL_DATABASE.containers (user_id,container_type,expiration_date,mac,ip_address) VALUES (\"$USER_ID\",\"$CONTAINER_TYPE\",\"NOW()\",\"$MAC\",\"$IP\");"
		echo "$SQL_UPDATE_GENERATED" | $MYSQL_CMD

		# Delete from pending table
		SQL_CLEAN="DELETE FROM $MYSQL_DATABASE.pending_containers WHERE id=$i"
		echo "$SQL_CLEAN" | $MYSQL_CMD
	done
	[ $? -eq 0 ]  && return 0 || return 1
}


# @return container_id for pending container creation
function checkPendingContainer () {
	info "Looking for pending containers creation"
	local i
    local SQL_REVIEW="SELECT id FROM $MYSQL_DATABASE.pending_containers;"
    local PENDING_IDS=`echo $SQL_REVIEW | $MYSQL_CMD`

    if [ -z "$PENDING_IDS" ]; then
    	info "Found 0 containers"
    else
    	info "Found $((${#PENDING_IDS[@]} +2)) containers to be processed: Starting"
    	for i in ${PENDING_IDS}; do
    		createContainer $i
    	done
    fi
}


function renewContainer () {
	info ""
}


function suspendContainer () {
	info ""
}