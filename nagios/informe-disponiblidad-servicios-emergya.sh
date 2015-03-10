#!/usr/bin/env bash

# VARS
USER="mpanzuela"
PASS="Direla2012"
DATE=`date +%Y%m%d-%H%M%S`
REPORT="Emergya-report-$DATE"
REPORT_TEMP="tmp-Emergya-report-$DATE"
REPORT_DIR="/home/moro/nagios"
TITLE="Emergya Availability Critical Services Report"

# Checks
[ ! -d $REPORT_DIR ] && mkdir -p $REPORT_DIR && echo -e "[INFO] Creating $REPORT_DIR ..."

function getWebReport () {
	echo -e "[INFO] Getting $TITLE..."
	wget --no-check-certificate  --http-user=$USER --http-password=$PASS "https://nagios.emergya.es/nagios/cgi-bin/avail.cgi?t1=1420066800&t2=1425666215&\
	show_log_entries=&hostgroup=emergya-critical-services&assumeinitialstates=yes&assumestateretention=yes&assumestatesduringnotrunning=yes&includesoftstates=no\
	&initialassumedhoststate=3&initialassumedservicestate=0&timeperiod=lastmonth&backtrack=10" -O $REPORT_DIR/$REPORT
}

function cleanReport () {
	echo -e "[INFO] Cleaning $TITLE..."
	sed -n -e '/TH CLASS/p' -e '/tr CLASS/p' $REPORT_DIR/$REPORT > $REPORT_DIR/$REPORT_TEMP
	cat $REPORT_DIR/$REPORT_TEMP | sed "s/<a.*yes'>//g" | sed 's/<\/a>//g' | sed "s/<\/table>//g" | sed "s/'/\"/g" > $REPORT_DIR/$REPORT

	cat $REPORT_DIR/$REPORT | sed "s/TH CLASS="data"/td/g" | sed 's/\/TH/\/td/g'  > $REPORT_DIR/$REPORT_TEMP


}

getWebReport

cleanReport