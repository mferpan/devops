#!/usr/bin/env bash
# Description: Manage containers opereations

function containerOperation () {
	local CONTAINER=$1
	local OPERATION=$2
	case $OPERATION in
		freeze) lxc-unfreeze -n $CONTAINER ;;
        unfreeze) lxc-unfreeze -n $CONTAINER ;;
        stop) lxc-stop --force -n $CONTAINER ;;
        start) lxc-start -dn $CONTAINER ;;
        *) error "Invalid Operation $OPERATION" && return 1 ;;
    esac

	if [ $? -eq 0 ]; then
		info "$OPERATION operation over container $CONTAINER"
		return 0
	else
		error "Container $CONTAINER failed while $OPERATION"
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

function checkRoot () {
	[ $(id -u) != "0" ] && error "You are NOT root user" && exit 1
}

