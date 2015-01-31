#!/bin/bash

function filesystem_backup {
  local server=$1
  local DATE=`date "+%Y%m%d-%H%M%S"`
  EMAIL=sistemas@emergya.com

  get_object_parameter $server ip $SERVERS_CONFIG
  [ -z $VALUE ] && server_ip=$server || server_ip=$VALUE

  # Rsync stuff
  BASEDIR=`readlink -m $dirname/../backups`
  BACKUP_BASE=$BASEDIR/$ENVIRONMENT/$server
  INCREMENTAL_BACKUP_DIR=$BACKUP_BASE/incremental
  FULL_BACKUP_DIR=$BACKUP_BASE/full
  CONFIG_BASE=$CONFIG_DIR/$ENVIRONMENT/backup/$server
  FILES_FROM=$CONFIG_BASE/include
  EXCLUDE_FROM=$CONFIG_BASE/exclude
  
  LAST_INCREMENTAL_DIR=`ls -t $INCREMENTAL_BACKUP_DIR | head -1`

  [ ! -r $FILES_FROM.static ] && error "Could not find backup config file $FILES_FROM.static - Discarding backup for server $server..." && return
  [ ! -r $EXCLUDE_FROM.static ] && error "Could not find backup config file EXCLUDE_FROM.static - Discarding backup for server $server..." && return
  if [ ! -d $BACKUP_BASE ]; then
     mkdir -p $BACKUP_BASE
     [ $? -ne 0 ] && error "Could not create base backup directory $BACKUP_BASE - Discarding backup for server $server..." && return
  fi
  if [ ! -d $INCREMENTAL_BACKUP_DIR ]; then
     mkdir -p $INCREMENTAL_BACKUP_DIR
     [ $? -ne 0 ] && error "Could not create backup destination directory $INCREMENTAL_BACKUP_DIR - Discarding backup for server $server..." && return
  fi
  
  [ ! -w $BACKUP_BASE ] && error "Cannot write on base backup directory $BACKUP_BASE - Discarding backup for server $server..." && return
  [ ! -w $INCREMENTAL_BACKUP_DIR ] && error "Cannot write on destination backup directory $INCREMENTAL_BACKUP_DIR - Discarding backup for server $server..." && return
  [ ! -w $CONFIG_BASE ] && error "Cannot write on config directory $CONFIG_BASE - Discarding backup for server $server..." && return
  
  [ -r $EXCLUDE_FROM.dynamic ] && . $EXCLUDE_FROM.dynamic >> $EXCLUDE_FROM

  get_object_parameter $server "backup_retention_days" $SERVERS_CONFIG
  RETENTION_DAYS=$VALUE

  get_object_parameter $server "full_backup_retention_days" $SERVERS_CONFIG
  FULL_RETENTION_DAYS=$VALUE

  # Send include/exclude files to server
  get_object_parameter $server "user" $SERVERS_CONFIG
  [ -z $VALUE ] && warning "filesystem_backup function: Could not find remote user execution for server $server in configuration file $SERVERS_CONFIG - Discarding backup..." && return
  EXECUTION_USER=$VALUE
  CFG_COPY_CMD="rsync -avz --bwlimit=5000 $CONFIG_BASE $EXECUTION_USER@$server_ip:/root/"
  info "Copying backup configuration into remote server $server... Executing $CFG_COPY_CMD"
  RSYNC_OUTPUT=`$CFG_COPY_CMD 2>&1`
  if [ $? -ne 0 ]; then
     error "filesystem_backup function: Could not copy backup configuration files to server $server - Discarding backup..."
     [ ! -z "$RSYNC_OUTPUT" ] && error "Error was: $RSYNC_OUTPUT"
     return
  fi

  # Let's fill include/exclude files with dynamic files listing...
  REMOTE_CONFIG_DIR=/root/`basename $CONFIG_BASE`
  for contentFile in include exclude; do
    execute_remote_command $EXECUTION_USER "cat $REMOTE_CONFIG_DIR/$contentFile.static > $REMOTE_CONFIG_DIR/$contentFile" $server
    if [ $? -ne 0 ]; then
       error "filesystem_backup function: Could not create $REMOTE_CONFIG_DIR/$contentFile \(static\) in server $server - Discarding backup..."
       [ ! -z "$EXECUTION_RESULT" ] && error "Error was: $EXECUTION_RESULT"
       return
    fi
    if [ -r $CONFIG_BASE/$contentFile.dynamic ]; then
       execute_remote_command $EXECUTION_USER ". $REMOTE_CONFIG_DIR/$contentFile.dynamic >> $REMOTE_CONFIG_DIR/$contentFile" $server
       if [ $? -ne 0 ]; then
          error "filesystem_backup function: Could not create $REMOTE_CONFIG_DIR/$contentFile \(dynamic\) in server $server - Discarding backup..."
          [ ! -z "$EXECUTION_RESULT" ] && error "Error was: $EXECUTION_RESULT"
          return
       fi
     fi
     CFG_COPY_CMD="rsync -avz --bwlimit=2000 $EXECUTION_USER@$server_ip:$REMOTE_CONFIG_DIR/$contentFile $CONFIG_BASE"
     info "Copying backup file $REMOTE_CONFIG_DIR/$contentFile from server $server, executing command $CFG_COPY_CMD"
     RSYNC_OUTPUT=`$CFG_COPY_CMD 2>&1`
     if [ $? -ne 0 ]; then
        error "filesystem_backup function: Could not copy backup configuration files $REMOTE_CONFIG_DIR/$contentFile from server $server - Discarding backup..."
        [ ! -z "$RSYNC_OUTPUT" ] && error "Error was: $RSYNC_OUTPUT"
        return
     fi
  done

  # Check if today is Sunday or FULL backup exists
  if [ `date +%a` = "Mon" ] || [ ! -d $FULL_BACKUP_DIR ]; then
     # Compress full backup if exists older than 7 days...
     for z in `ls $FULL_BACKUP_DIR | grep -v .tar.bz2$`; do
        COMPRESS_FULL_BACKUP_CMD="tar -cvjf $FULL_BACKUP_DIR/$z.tar.bz2 $FULL_BACKUP_DIR/$z"
        info "Compressing full backup dir $FULL_BACKUP_DIR/$z into file $FULL_BACKUP_DIR/$z.tar.bz2 - Executing command: $COMPRESS_FULL_BACKUP_CMD"
        COMPRESS_OUTPUT=`$COMPRESS_FULL_BACKUP_CMD 2>&1`
        COMPRESS_EXIT=$?

        if [ $COMPRESS_EXIT -eq 0 ]; then
           info "Compression completed. Result was: $COMPRESS_OUTPUT"
           info "Deleting compressed directory $FULL_BACKUP_DIR/$z"
           rm -fr $FULL_BACKUP_DIR/$z
        else
           info "$COMPRESS_OUTPUT"
        fi
     done
     # Create and sync data
     mkdir -p $FULL_BACKUP_DIR/$DATE
     [ $? -ne 0 ] && error "Could not create base backup directory $FULL_BACKUP_DIR/$DATE - Discarding backup for server $server..." && return
     [ ! -w $FULL_BACKUP_DIR ] && error "Cannot write on destination backup directory $FULL_BACKUP_DIR - Discarding backup for server $server..." && return

     BACKUP_CMD="rsync -A -X -S -avz -r --bwlimit=2000 --delete-after --include-from=$FILES_FROM --files-from=$FILES_FROM --exclude-from=$EXCLUDE_FROM $EXECUTION_USER@$server_ip:/ $FULL_BACKUP_DIR/$DATE"
     SUBJECT="Emergya Systems Full Backup Report"
     TYPE="Full"
     # Compres porevious incremental backup
     for j in `ls $INCREMENTAL_BACKUP_DIR | grep -v .tar.bz2$`; do
        if [ $DATE != $j ]; then # Do not compress directory just created
           COMPRESS_INCREMENTAL_BACKUPS_CMD="tar -cvjf $INCREMENTAL_BACKUP_DIR/$j.tar.bz2 $INCREMENTAL_BACKUP_DIR/$j"
           info "Compressing incremental backup dir $INCREMENTAL_BACKUP_DIR/$j into file $INCREMENTAL_BACKUP_DIR/$j.tar.bz2 - Executing command: $COMPRESS_INCREMENTAL_BACKUPS_CMD"
           COMPRESS_OUTPUT=`$COMPRESS_INCREMENTAL_BACKUPS_CMD 2>&1`
           COMPRESS_EXIT=$?

           if [ $COMPRESS_EXIT -eq 0 ]; then
              info "Compression completed. Result was:"
              info "$COMPRESS_OUTPUT"
              rm -fr $INCREMENTAL_BACKUP_DIR/$j
           else
              info "$COMPRESS_OUTPUT"
           fi
        fi
     done
  else
     LAST_FULL_DIR=`ls $FULL_BACKUP_DIR | grep -v .tar.bz2$`
     SUBJECT="Emergya Systems Incremental Backup Report"
     TYPE="Incremental"
     INCREMENTAL_DIRS=""

     # Get incremental directories
     INCLUDE_CLAUSE=" --compare-dest="
     for i in `ls $INCREMENTAL_BACKUP_DIR | grep -v .tar.bz2$`; do
        INCREMENTAL_DIRS=$INCREMENTAL_DIRS$INCLUDE_CLAUSE$INCREMENTAL_BACKUP_DIR/$i
     done

     # All incremental directories are new, DO NOT DELETE ANYTHING...
     BACKUP_CMD="rsync -A -X -S -avz -r --bwlimit=2000 --compare-dest=$FULL_BACKUP_DIR/$LAST_FULL_DIR $INCREMENTAL_DIRS --include-from=$FILES_FROM --files-from=$FILES_FROM --exclude-from=$EXCLUDE_FROM $EXECUTION_USER@$server_ip:/ $INCREMENTAL_BACKUP_DIR/$DATE"
  fi

  info "Backing up server $server. Executing command: $BACKUP_CMD"
  BACKUP_OUTPUT=`$BACKUP_CMD 2>&1`
  BACKUP_EXIT=$?

  if [ -d $INCREMENTAL_BACKUP_DIR/$DATE ]; then
     echo "Cleaning incremental directory $INCREMENTAL_BACKUP_DIR/$DATE"
     find $INCREMENTAL_BACKUP_DIR/$DATE/* -depth -type d -exec rmdir {} \;
  fi

  # delete include and exclude programmatically generated files
  rm -f $FILES_FROM 2>&1 >/dev/null
  rm -f $EXCLUDE_FROM 2>&1 >/dev/null
  if [ $BACKUP_EXIT -eq 0 ]; then
     info "Backup completed. Result was:"
     info "$BACKUP_OUTPUT"
  else
     BACKUP_FAILED=true
     warning "$BACKUP_OUTPUT"
  fi

  # Removing old incremental...
  if [ -z $RETENTION_DAYS ]; then
     warning "Could not find backup_retention_days parameter for server $server in config file $SERVERS_CONFIG - Not cleaning old backups"
     return
  fi

  if [ -d $INCREMENTAL_BACKUP_DIR ]; then
     CLEANUP_CMD="find $INCREMENTAL_BACKUP_DIR -maxdepth 1 -mindepth 1 -mtime +$RETENTION_DAYS -type f -exec rm -vrf {} \;"
     info "Cleaning up old backups. Executing command: $CLEANUP_CMD"
     CLEANUP_OUTPUT=`eval $CLEANUP_CMD 2>&1`
     if [ -z "$CLEANUP_OUTPUT" ]; then
        info "0 previous backup deleted"
     else
        info "Cleanup completed. Result was:"
        info "$CLEANUP_OUTPUT" 
     fi
  else
     warning "No previous backup found in $INCREMENTAL_BACKUP_DIR"
  fi

  # Removing old full...
  if [ -z $FULL_RETENTION_DAYS ]; then
     warning "Could not find full_backup_retention_days parameter for server $server in config file $SERVERS_CONFIG - Not cleaning old full backups"
     return
  fi

  #if [ -d $FULL_BACKUP_DIR ]; then
     CLEANUP_CMD="find $FULL_BACKUP_DIR -maxdepth 1 -mindepth 1 -mtime +$FULL_RETENTION_DAYS -type f -exec rm -vrf {} \;"
     info "Cleaning up old full backups. Executing command: $CLEANUP_CMD"
  #   CLEANUP_OUTPUT=`eval $CLEANUP_CMD 2>&1`
  #   if [ -z "$CLEANUP_OUTPUT" ]; then
  #      info "0 previous full backup deleted"
  #   else
  #      info "Cleanup completed. Result was:"
  #      info "$CLEANUP_OUTPUT"
  #   fi
  #else
  #   warning "No previous full backup found in $FULL_BACKUP_DIR"
  #fi

  [ "$BACKUP_FAILED" = "true" ] && warning "Some content might not be copied - review it!"
  
  BODY="... $server Backup Report...
  Included files: `cat $FILES_FROM.static`
  Excluded files: `cat $EXCLUDE_FROM.static`
  Backup Output: $BACKUP_OUTPUT
  For more details, please follow the link below http://backup-report.emergya.es"

  echo "$BODY" | mail -s "$SUBJECT" $EMAIL

}

