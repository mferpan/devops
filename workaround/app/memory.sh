#!/usr/bin/env bash
# Description: Manage containers memory

function getFreeMemory () {
	local THEREIS=FALSE
	for i in $VOLGROUP_ARRAY; do
		local FREE_SPACE=`vgs --noheadings | awk '{print $NF}' | awk -F, '{print $1}'`

		if [ $FREE_SPACE -gt $VOLGROUP_MIN_FREE_SPACE ]; then
			return $i
			info "$i volgroup selected for new container"
			break
		fi
	done
	[ "$THEREIS" = "FALSE" ] && error "No free space available"
}


function updateMemorySize () {
	local containerID=$1
	local containerMemory=$2

	[ -z $containerID ] && error "Container ID not indicated" && exit 1
	[ -z $containerMemory ] && error "New memory size not indicated" && exit 1

	updateContainer $containerID memory $containerMemory
}
