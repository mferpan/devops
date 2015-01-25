#!/usr/bin/env bash
# Description: Manage containers opereations

function unfreezeContainer () {
	local CONTAINER=$1
	lxc-unfreeze -n $CONTAINER
	
	if [ $? -eq 0 ]; then
		info "Unfreezing container $CONTAINER"
		return 0
	else
		error "Container $CONTAINER failed while unfreezing"
		return 1
	fi
}

function freezeContainer () {
	local CONTAINER=$1
	lxc-freeze -n $CONTAINER
	
	if [ $? -eq 0 ]; then
		info "Freezving container $CONTAINER"
		return 0
	else
		error "Container $CONTAINER failed while freezing"
		return 1
	fi
}

function stopContainer () {
	local CONTAINER=$1
	lxc-stop --force -n $CONTAINER
	
	if [ $? -eq 0 ]; then
		info "Removing container $CONTAINER"
		return 0
	else
		error "Container $CONTAINER failed while removing"
		return 1
	fi
}

function startContainer () {
	local CONTAINER=$1
	lxc-start -dn $CONTAINER

	if [ $? -eq 0 ]; then
		info "Starting container $CONTAINER"
		return 0
	else
		error "Container $CONTAINER failed while starting"
		return 1
	fi
}

function removeContainer () {
	local CONTAINER=$1
	lxc-destroy --force -n $CONTAINER
	
	if [ $? -eq 0 ]; then
		info "Removing container $CONTAINER"
		return 0
	else
		error "Container $CONTAINER failed while removing"
		return 1
	fi
}

# updateContainer $containerID {disk,memory,cpu} $newSize
function updateContainer () {
	local CONTAINER_ID=$1
	local ATTRIBUTE=$2
	local NEW_SIZE=$3

	[ -z $CONTAINER_ID ] && error "Value of CONTAINER_ID variable is NULL" && exit 1
	[ -z $ATTRIBUTE ] && error "Value of ATTRIBUTE variable is NULL" && exit 1
	[ -z $NEW_SIZE ] && error "Value of NEW_SIZE variable is NULL" && exit 1

	info "updateContainer"
}


