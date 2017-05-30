#!/bin/bash

function downloadEmail() {
        [ ! -d ${INBOX} ] && mkdir -p ${INBOX}
        [ ! -f ${LOG} ] && touch ${LOG}
        info " __ Mail Download Process starting"
        ${FM_CMD} --fetchmailrc ${CONF_DIR}/fetchmailrc --logfile ${LOG}
}

function sendReport() {
    local OK=($(echo "$1" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    local WR=($(echo "$2" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    local ER=($(echo "$3" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    local NP=($(echo "$4" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    local BODY="Backup report generated at $(date +%Y/%m/%d-%H:%M:%S) <br /><br /><br />"

	if [ ! -z "$OK" ]; then
		SUBJECT="[OK] There are ${#OK[@]} backups correct"
		BODY+="There are ${#OK[@]} clients with backups in <font color=\"green\">OK</font> state: <br /><font color=\"green\">"
		for CLT in ${OK[*]}; do BODY+=" > ${CLT}<br />"; done
		BODY+="</font><br />"
	fi

	if [ ! -z "$WR" ]; then
		SUBJECT="[WARNING] There are ${#WR[@]} clients with warning"
		BODY+="There are ${#WR[@]} clients with backups in <font color=\"orange\">WARNING</font> state: <br /><font color=\"orange\">"
		for CLT in ${WR[*]}; do BODY+=" > ${CLT}<br />"; done
		BODY+="</font><br />"
	fi

	if [ ! -z "$ER" ]; then
		SUBJECT="[ERROR] There are ${#ER[@]} clients with errors"
		BODY+="There are ${#ER[@]} clients with backups in <font color=\"red\">ERROR</font> state: <br /><font color=\"red\">"
		for CLT in ${ER[*]}; do BODY+=" > ${CLT}<br />"; done
		BODY+="</font><br />"
	fi

    if [ ! -z "$NP" ]; then
            SUBJECT="[ERROR] There are ${#NP[@]} clients without backup report"
            BODY+="There are ${#NP[@]} clients <font color=\"purple\">WITHOUT</font> backup report:<br /><font color=\"purple\">"
            for CLT in ${NP[*]}; do BODY+=" > ${CLT}<br />"; done
            BODY+="</font><br />"
    fi

	if [ -z "$OK" ] && [ -z "$WR" ] && [ -z "$ER" ] && [ -z "$NP" ]; then
		SUBJECT="[ERROR] NO backups to check, Is it correct?"
		BODY+="<font color=\"red\">NO backups to check Is it correct?</font><br />"
	fi

	echo "${BODY}" | mutt -e "set realname=\"${SENDER}\"" -e "set content_type=text/html" -s "${SUBJECT}" "${REPORT_MAIL_ADDRESS}"
}


function parseEmail() {
	getClients

	local CLIENTS_OK=""
	local CLIENTS_WR=""
	local CLIENTS_ER=""
	local CLIENTS_NP=""
	local FLAG=false

 	[ ! -d $ARCHIVED ] && mkdir -p ${ARCHIVED}
 	[ -z "$CLIENTS" ] && error "NO clients found in the database"

	TOTAL_EMAILS=$(ls ${INBOX} | wc -l)

	for CLI in $CLIENTS; do
		for MAIL in $(ls ${INBOX}); do
			# Checking Proxmox backups
			if (grep -E "^Subject.*${CLI}.*successful" ${INBOX}/${MAIL}); then
				mv ${INBOX}/${MAIL} ${CLIENTS_BASE}/${CLI}
				CLIENTS_OK+=" ${CLI}"
				insertStatus ${CLI} 0
				FLAG=true
			elif (grep -E "^Subject.*${CLI}.*failed" ${INBOX}/${MAIL}); then
				mv ${INBOX}/${MAIL} ${CLIENTS_BASE}/${CLI}
				CLIENTS_ER+=" ${CLI}"
				insertStatus ${CLI} 2
				FLAG=true
			fi

			# Checking another emails
			if (grep -E "^Subject.*(correctamente|Correcto|Success|satisfactorio|satisfactoria).*${CLI}" ${INBOX}/${MAIL}); then
				mv ${INBOX}/${MAIL} ${CLIENTS_BASE}/${CLI}
				CLIENTS_OK+=" ${CLI}"
				insertStatus ${CLI} 0
				FLAG=true
			elif  (grep -E "^Subject.*(Aviso|Warning|avisos|perdida).*${CLI}" ${INBOX}/${MAIL}); then
				mv ${INBOX}/${MAIL} ${CLIENTS_BASE}/${CLI}
				CLIENTS_WR+=" ${CLI}"
				insertStatus ${CLI} 1
				FLAG=true
			elif (grep -E "^Subject.*con.*(errores|Fallo|Failed).*${CLI}" ${INBOX}/${MAIL}); then
				mv ${INBOX}/${MAIL} ${CLIENTS_BASE}/${CLI}
				CLIENTS_ER+=" ${CLI}"
				insertStatus ${CLI} 2
				FLAG=true
			fi
		done
		if [ "$FLAG" = false ]; then
			CLIENTS_NP+=" ${CLI}"
			insertStatus ${CLI} 3
		fi
		FLAG=false
	done

	# Spam mails will be archived
	info " __ Sending NON processed emails to ${ARCHIVED} directory"
	mv ${INBOX}/*.eml ${ARCHIVED}

	sendReport "${CLIENTS_OK}" "${CLIENTS_WR}" "${CLIENTS_ER}" "${CLIENTS_NP}"

	# Clean variable
	unset CLIENTS
}

function compressEmails(){
	local D=$(date +%Y%m -d 'last month')

	for C in $(ls ${CLIENTS_BASE}); do
		TAR_DIR="${CLIENTS_BASE}/${C}/${D}"

		[ "$(ls -A ${CLIENTS_BASE}/${C}/*.eml 2>&1)" ] && continue

		mkdir -p ${TAR_DIR}
		mv ${CLIENTS_BASE}/${C}/*.eml ${TAR_DIR}

		tar czf ${CLIENTS_BASE}/${C}/$(date +%Y%m%d%H%M%S).tar.gz ${TAR_DIR}
		[ $? -eq 0 ] && rm -fr ${TAR_DIR}
	done
}

function listClients() {
	echo "There are ${TOTAL_CLIENTS[*]} clients"
	for C in $(ls ${CLIENTS_BASE}); do
		echo "   ---> ${C}"
	done
}

function createClient() {
	local NAME

	echo "Insert client name: "
	read NAME
	[ "${NAME}" = "" ] && echo "[ERROR] Name can't be null" && exit 1

	mkdir -p ${CLIENTS_BASE}/${NAME}
	[ $? -eq 0 ] && echo "[INFO] Client ${NAME} created sucessfully"
}

function prepareInbox() {
	mv ${ARCHIVED}/* ${INBOX}/
}

function download() {
	info " __ Prepare previous emails to be processed"
	prepareInbox

	info " __ Downloading emails process has started"
	downloadEmail
	parseEmail
	rotate_logs
	[ $(date +%e) -eq ${COMPRESS_DAY} ] && compressEmails
	info " ____ FINISHED ____"
}

function menu() {
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

