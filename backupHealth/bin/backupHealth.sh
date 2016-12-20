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
LOG="${LOGS_DIR}/fetchmailrc-${DATE}.log"
COMPRESS_DAY="1"

REPORT_MAIL_ADDRESS="glpi@inovages.es"
SENDER="backup@grupoinova.es"

TOTAL_CLIENTS=$(ls ${CLIENTS_BASE} | wc -l)

# To Do
# Verify that for each company we have got backup emails

# -------- Functions --------
downloadEmail() {
        [ ! -d ${INBOX} ] && mkdir -p ${INBOX}
        [ ! -f ${LOG} ] && touch ${LOG}
        echo "# -------------- Mail Download Process starting - $(date +%Y/%m/%d-%H:%M:%S) -------------- #" >> ${LOG}
        ${FM_CMD} --fetchmailrc ${CONF_DIR}/fetchmailrc --logfile ${LOG}
}

sendReport() {
    local OK=($(echo "$1" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    local WR=($(echo "$2" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    local ER=($(echo "$3" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    local BODY="Backup report generated at $(date +%Y/%m/%d-%H:%M:%S) <br /><br /><br />"

	if [ ! -z "$OK" ]; then
		SUBJECT="[OK] There are ${#OK[@]} backups correct"
		BODY+="There are ${#OK[@]} clients with backups in <font color=\"green\">OK</font> state: <br /><font color=\"green\">"
		for host in ${OK[*]}; do BODY+=" > ${host}<br />"; done
		BODY+="</font><br />"
	fi

	if [ ! -z "$WR" ]; then
		SUBJECT="[WARNING] There are ${#WR[@]} clients with warning"
		BODY+="There are ${#WR[@]} clients with backups in <font color=\"orange\">WARNING</font> state: <br /><font color=\"orange\">"
		for host in ${WR[*]}; do BODY+=" > ${host}<br />"; done
		BODY+="</font><br />"
	fi

	if [ ! -z "$ER" ]; then
		SUBJECT="[ERROR] There are ${#ER[@]} clients with errors"
		BODY+="There are ${#ER[@]} clients with backups in <font color=\"red\">ERROR</font> state: <br /><font color=\"red\">"
		for host in ${ER[*]}; do BODY+=" > ${host}<br />"; done
		BODY+="</font><br />"
	fi

	if [ -z "$OK" ] && [ -z "$WR" ] && [ -z "$ER" ]; then
		SUBJECT="[ERROR] NO backups to check, Is it correct?"
		BODY+="<font color=\"red\">NO backups to check Is it correct?</font><br />"
	fi

	echo "${BODY}" >> ${LOG}
	echo -e "\n\n" >> ${LOG}

	echo "${BODY}" | mutt -e "set realname=\"${SENDER}\"" -e "set content_type=text/html" -s "${SUBJECT}" "${REPORT_MAIL_ADDRESS}"
}


parseEmail() {
	local CLIENTS=$(ls ${CLIENTS_BASE})
	local CLIENTS_OK=""
	local CLIENTS_WR=""
	local CLIENTS_ER=""

 	[ ! -d $ARCHIVED ] && mkdir -p ${ARCHIVED}

	TOTAL_EMAILS=$(ls ${INBOX} | wc -l)

	for CLI in $CLIENTS; do
		for MAIL in $(ls ${INBOX}); do
			# Checking Proxmox backups
			if (grep "^Subject.*${CLI}.*successful" ${INBOX}/${MAIL}); then
				mv ${INBOX}/${MAIL} ${CLIENTS_BASE}/${CLI}
				CLIENTS_OK+=" ${CLI}"
			elif (grep "^Subject.*${CLI}.*failed" ${INBOX}/${MAIL}); then
				mv ${INBOX}/${MAIL} ${CLIENTS_BASE}/${CLI}
				CLIENTS_ER+=" ${CLI}"
			fi

			# Checking other emails
			if (grep "^Subject.*correctamente.*${CLI}" ${INBOX}/${MAIL}); then
				mv ${INBOX}/${MAIL} ${CLIENTS_BASE}/${CLI}
				CLIENTS_OK+=" ${CLI}"
			elif (grep "^Subject.*Correcto.*${CLI}" ${INBOX}/${MAIL}); then
				mv ${INBOX}/${MAIL} ${CLIENTS_BASE}/${CLI}
				CLIENTS_OK+=" ${CLI}"
			elif (grep "^Subject.*satisfactorio.*${CLI}" ${INBOX}/${MAIL}); then
				mv ${INBOX}/${MAIL} ${CLIENTS_BASE}/${CLI}
				CLIENTS_OK+=" ${CLI}"
			elif  (grep "^Subject.*Aviso.*${CLI}" ${INBOX}/${MAIL}); then
				mv ${INBOX}/${MAIL} ${CLIENTS_BASE}/${CLI}
				CLIENTS_WR+=" ${CLI}"
			elif  (grep "^Subject.*perdida.*${CLI}" ${INBOX}/${MAIL}); then
				mv ${INBOX}/${MAIL} ${CLIENTS_BASE}/${CLI}
				CLIENTS_WR+=" ${CLI}"
			elif (grep "^Subject.*con.*errores.*${CLI}" ${INBOX}/${MAIL}); then
				mv ${INBOX}/${MAIL} ${CLIENTS_BASE}/${CLI}
				CLIENTS_ER+=" ${CLI}"
			elif  (grep "^Subject.*Fallo.*${CLI}" ${INBOX}/${MAIL}); then
				mv ${INBOX}/${MAIL} ${CLIENTS_BASE}/${CLI}
				CLIENTS_ER+=" ${CLI}"
			fi
		done
	done

	# Spam mails will be archived
	echo "[ARVCHIVING] Sending NON processed emails to ${ARCHIVED} directory"
	mv ${INBOX}/*.eml ${ARCHIVED}

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

cleanArchived() {
	find ${ARCHIVED} -mtime +31 -type f -delete
}

listClients() {
	echo "There are ${TOTAL_CLIENTS[*]} clients"
	for C in $(ls ${CLIENTS_BASE}); do
		echo "   ---> ${C}"
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

prepareInbox() {
	mv ${ARCHIVED}/* ${INBOX}/
}

download() {
	echo "[START] Prepare previous mails to be processed"
	prepareInbox

	echo "[START] Downloading emails process has started"
	downloadEmail
	parseEmail
	cleanLogs
	cleanArchived
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
