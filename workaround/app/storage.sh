#!/usr/bin/env bash

# Get free space from available volgroups
function checkVolgroupFreeSpace {
  local THEREIS=FALSE
  VG_FREE_SPACE=`vgs --noheadings | grep -i $VOLGROUP | awk '{print $NF}' | awk -F, '{print $1}'`
  [[ $VG_FREE_SPACE -gt $VOLGROUP_MIN_FREE_SPACE ]] && return 0 || return 1
}


function mountPartition () {
  local ID=$1
  mkdir -p $LXC_ROOT/$ID
  $MOUNT /dev/$VOLGROUP/$ID $LXC_ROOT/$ID
}


function fstabUpdate () {
  local ID=$1

  if [ -z $ID ]; then
    error "Something was wrong while FSTAB update" && return 1
  else
    echo "/dev/$VOLGROUP/$ID $LXC_ROOT/$ID ext4 defaults 1 2" >> /etc/fstab
    [ $? -ne 0 ] && error "Something was wrong while FSTAB update" && return 1
  fi
}


function formatPartition () {
  mkfs.ext4 -F /dev/$VOLGROUP/$1

  if [ $? -ne 0 ]; then
    error "Something was wrong with partition $1"
  else
    fstabUpdate $1
  fi
}


function createStorage () {
  local USER_ID=$1
  local CONTAINER_TYPE=$2
  local SQL_GET_DEFINITION="SELECT disk_size FROM $MYSQL_DATABASE.container_definition WHERE name=\"$CONTAINER_TYPE\";"
  local DISK_SIZE=`echo $SQL_GET_DEFINITION | $MYSQL_CMD`

  checkVolgroupFreeSpace
  [ $? -ne 0 ] && error "There is NO volgroup with FREE space available" && exit 1

  DISK_SIZE_MB=`echo $DISK_SIZE | sed s/000$//g`
  
  if [[ $DISK_SIZE_MB -gt $VG_FREE_SPACE ]]; then
    error "There in NO free space available"
    return 1
  else
    $LVCREATE --yes -L $DISK_SIZE""M -n $USER_ID $VOLGROUP

    if [ $? -eq 0 ]; then
      formatPartition $USER_ID
      info "Storage $USER_ID generated"
      return 0
    else
      error "Something was wrong with storage generation"
      return 1
    fi
  fi
}


function deleteStorage () {
  local USER_ID=$1

  $LVREMOVE -f /dev/$VOLGROUP/$USER_ID

  if [ $? -eq 0 ]; then
    info "Storage $USER_ID removed"
    return 0
  else
    error "Something was wrong while lvremove"
    return 1
  fi
}


function updateStorage () {
  local containerID=$1
  local containerSize=$2

  [ -z $containerID ] && error "Container ID not indicated" && exit 1
  [ -z $containerSize ] && error "New Disk size not indicated" && exit 1

  updateContainer $containerID disk $containerSize
  return 1
}
