#!/bin/bash

MYSQL_SERVER="192.168.1.100"
MYSQL_PORT="3306"
MYSQL_DB="backupHealth"
MYSQL_USER="backupHealth"
MYSQL_PASS="backupHealth"

MYSQL_CMD="mysql -s -u ${MYSQL_USER} -p${MYSQL_PASS} ${MYSQL_DB} -h ${MYSQL_SERVER} -P ${MYSQL_PORT}"