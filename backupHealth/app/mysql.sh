#!/bin/bash

# @return clients to check
function getClients {
    info " __ Getting clients from database"

    [[ $(date +%u) -gt 5 ]] && DOW="MS" || DOW="MF"
    SQL="SELECT name FROM $MYSQL_DATABASE.clients where backup_type_id=(select type_id from backup_type where type='${DOW}');"
    
    CLIENTS=`echo $SQL | $MYSQL_CMD`

    if [ -z "$CLIENTS" ]; then
        info " __ Found 0 clients to be processed"
    else
        info " __ Found $((${#CLIENTS[@]} +2)) clients to be processed"
    fi
}

function insertStatus {
    local CL=$1
    local ST=$2

    info " __ __ Status $ST for client $CL"
    SQL_STATUS="INSERT INTO backup_report (client_id,report_date,status) VALUES ((SELECT client_id from clients WHERE client_id=\"$CL\"),NOW(),$ST);"
    echo $SQL_STATUS | $MYSQL_CMD
}