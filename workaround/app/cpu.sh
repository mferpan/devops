#!/usr/bin/env bash
# Description: Manage containers CPU

function getFreeCPU () {
	local ACTUAL_USAGE=`top -bn1 | awk '/Cpu/ { cpu = 100 - $8 }; END { print cpu }'`
	return $ACTUAL_USAGE
}


function updateCPU () {
	local containerID=$1
	local containerMemory=$2

	[ -z $containerID ] && error "Container ID not indicated" && exit 1
	[ -z $containerMemory ] && error "New memory size not indicated" && exit 1

	updateContainer $containerID memory $containerMemory
}
