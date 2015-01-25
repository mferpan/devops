#!/usr/bin/env bash
# Description: Manage containers network

function getIP () {
	LAST_IP=`lxc-ls -f | grep -iv ipv | awk '{print $3}' | sort | tail -1 | awk -F. '{print $4}'`
	if [ -z $LAST_IP ]; then
		IP=$IP_START
	else
		IP=$NETWORK.$((LAST_IP+1))
	fi
}


function getContainerTraffic (){
	ifconfig wlp2s0 | grep 'RX'
}