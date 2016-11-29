#!/bin/bash

# -------- Vars --------
BASE="/opt/backupHealth"
CONF_DIR="${BASE}/config"
CLIENTS_BASE="${BASE}/clients"
ARCHIVED="${BASE}/archived"
VZ_FOLDER="${CLIENTS_BASE}/vzdump"
LOGS_DIR="${BASE}/logs"
INBOX="${BASE}/inbox"

FM_CMD="/usr/bin/fetchmail"
DATE=$(date +%Y%m%d)
COMPRESS_DAY="1"

REPORT_MAIL_ADDRESS="manuel@mfernandez.es"
SENDER="backup-verifier@grupoinova.es"

TOTAL_CLIENTS=$(ls ${CLIENTS_BASE} | wc -l)

# ToDo
# Verify that each company has backup emails

# -------- Functions --------
downloadEmail() {
	local LOG="${LOGS_DIR}/fetchmailrc-${DATE}.log"

	[ ! -f ${LOG} ] && touch ${LOG}
	${FM_CMD} --fetchmailrc ${CONF_DIR}/fetchmailrc --logfile ${LOG}
}


sendReport() {
	local OK=$1
	local WR=$2
	local ER=$3
	local BODY="Backup report generated at ${DATE} <br /><br /><br />"

	if [ ! -z "$ER" ]; then
		SUBJECT="[ERROR] There are ${#ER[@]} clients with errors"
		BODY+="There are ${#ER[@]} clients with backups in ERROR state: <font color=\"red\"> ${ER[*]} </font><br />"
	fi
	if [ ! -z "$WR" ]; then
		[ -z "$ER" ] && SUBJECT="[WARNING] There are ${#WR[@]} clients with warning"
		BODY+="There are ${#WR[@]} clients with backups in WARNING state: <font color=\"orange\"> ${WR[*]} </font><br />"
	fi

	if [ ! -z "$OK" ] && [ -z "$WR" ] && [ -z "$ER" ]; then
		SUBJECT="[OK] There are ${#OK[@]} backups correct"
		BODY="There are ${#OK[@]} clients with backups in OK state: <font color=\"green\"> ${OK[*]} </font><br />"
	else
		BODY+="Clients with backups in OK state are: <font color=\"green\"> ${OK[*]} </font> <br />"
	fi

	if [ -z "$OK" ] && [ -z "$WR" ] && [ -z "$ER" ]; then
		SUBJECT="[ERROR] NO backups to check, Is it correct?"
		BODY="<font color=\"red\">NO backups to check Is it correct?</font><br />"
	fi

	echo "${BODY}" | mutt -e "set realname=\"${SENDER}\"" -e "set content_type=text/html" -s "${SUBJECT}" "${REPORT_MAIL_ADDRESS}"
}


parseEmail() {
	local CLIENTS=$(ls ${CLIENTS_BASE})
	local CLIENTS_OK=""
	local CLIENTS_WR=""
	local CLIENTS_ER=""

	TOTAL_EMAILS=$(ls ${INBOX} | wc -l)

	for CLI in $CLIENTS; do
		for MAIL in $(ls ${INBOX}); do

			# Checking Proxmox backups
			if (grep "vzdump.*successful" ${INBOX}/${MAIL}); then
				mv ${INBOX}/${MAIL} ${VZ_FOLDER}
			fi

			if (grep "Subject.*correctamente.*${CLI}" ${INBOX}/${MAIL}); then
				mv ${INBOX}/${MAIL} ${CLIENTS_BASE}/${CLI}
				CLIENTS_OK+=" ${CLI}"
			elif (grep "Subject.*con.*errores.*${CLI}" ${INBOX}/${MAIL}); then
				mv ${INBOX}/${MAIL} ${CLIENTS_BASE}/${CLI}
				CLIENTS_ER+=" ${CLI}"
			elif  (grep "Subject.*con.*avisos.*${CLI}" ${INBOX}/${MAIL}); then
				mv ${INBOX}/${MAIL} ${CLIENTS_BASE}/${CLI}
				CLIENTS_WR+=" ${CLI}"
			else
				# Spam mails will be deleted or archived
				echo "[ARVCHIVING] Sending ${MAIL} to ${ARCHIVED} directory"
				# rm -f ${INBOX}/${MAIL}
				mv ${INBOX}/${MAIL} ${ARCHIVED}
			fi
		done
	done

	sendReport "${CLIENTS_OK}" "${CLIENTS_WR}" "${CLIENTS_ER}"
}


compressEmails(){
	local D=$(date +%Y%m -d 'last month')

	for C in $(ls ${CLIENTS_BASE}); do
		TAR_DIR="${CLIENTS_BASE}/${C}/${D}"

		[ $(ls ${CLIENTS_BASE}/${C}/*.eml | wc -l) -eq 0 ] && continue

		mkdir -p ${TAR_DIR}
		mv ${CLIENTS_BASE}/${C}/*.eml ${TAR_DIR}

		tar czf ${CLIENTS_BASE}/${C}/$(date +%Y%m%d%H%M%S).tar.gz ${TAR_DIR}
		[ $? -eq 0 ] && rm -fr ${TAR_DIR}
	done
}


cleanLogs() {
	find ${LOGS_DIR} -mtime +31 -type f -delete
}


listClients() {
	local CLIENT
	echo "There are ${TOTAL_CLIENTS[*]} clients"
	for CLIENT in $(ls ${CLIENTS_BASE}); do
		echo "   ---> ${CLIENT}"
	done
}

createClient() {
	local NAME

	echo "Insert client name: "
	read NAME
	[ "${NAME}" = "" ] && echo "[ERROR] Name can't be null" && exit 1

	mkdir -p ${CLIENTS_BASE}/${NAME}
	[ $? -eq 0 ] && echo "[INFO] Client ${NAME} created sucessfully"
}

download() {
	echo "[START] Downloading emails process has started"
	downloadEmail
	parseEmail
	cleanLogs
	[ $(date +%e) -eq ${COMPRESS_DAY} ] && compressEmails
	echo "[FINISH]"
}

menu() {
	PS3='Please enter your choice: '
	options=("List Clients" "Create New Client" "Quit")
	select opt in "${options[@]}"
	do
	    case $opt in
			"List Clients")
				listClients
			;;
			"Create New Client")
				createClient
			;;
			"Quit")	break ;;
	        *)
				echo "[WARNING] Unknown option"
	        ;;
	    esac
	done
	exit 0
}

# -------- MAIN --------
[ "$1" = "auto" ] && download  || menu
