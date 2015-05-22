#!/usr/bin/env bash

# VARS
USER="mpanzuela"
PASS="XXXX"
DATE=`date +%Y%m%d-%H%M%S`
REPORT="Emergya-report-$DATE"
REPORT_NAGIOS="Emergya-nagios-report.html"
REPORT_TEMP="tmp-Emergya-report-$DATE"
REPORT_DIR=`pwd`
REPORT_TEMP_DIR="/tmp"
TITLE="Emergya Availability Critical Services Report"

function getWebReport () {
#	logger -t "[INFO] Getting $TITLE..."
	wget --no-check-certificate  --http-user=$USER --http-password=$PASS "https://nagios.emergya.es/nagios/cgi-bin/avail.cgi?t1=1420066800&t2=1425666215&\
	show_log_entries=&hostgroup=emergya-critical-services&assumeinitialstates=yes&assumestateretention=yes&assumestatesduringnotrunning=yes&includesoftstates=no\
	&initialassumedhoststate=3&initialassumedservicestate=0&timeperiod=lastmonth&backtrack=10" -O $REPORT_TEMP_DIR/$REPORT 2>&1
}

function prepareReport () {
#	logger -t "[INFO] Cleaning $TITLE..."
	sed -n -e '/TH CLASS/p' -e '/tr CLASS/p' $REPORT_TEMP_DIR/$REPORT > $REPORT_TEMP_DIR/$REPORT_TEMP
	cat $REPORT_TEMP_DIR/$REPORT_TEMP | sed "s/<a.*yes'>//g" | sed "s/<\/table>//g" | sed 's/<\/a>//g'> $REPORT_TEMP_DIR/$REPORT
	sed -e 's/\ [Cc][^>]*>/>/g' $REPORT_TEMP_DIR/$REPORT > $REPORT_TEMP_DIR/$REPORT_TEMP
}

function createReport () {
#	logger -t "[INFO] Generating report..."
	local NL=`wc -l $REPORT_TEMP_DIR/$REPORT_TEMP | awk {'print $1'}`
	
	# Clean
	cat cabecera.html > $REPORT_DIR/$REPORT_NAGIOS

	head -n1 $REPORT_TEMP_DIR/$REPORT_TEMP | sed 's/<TR>/<thead><tr>/g' | sed 's/<\/TR>/<\/tr><\/thead>/g' | sed 's/<TH>/<td>/g' >> $REPORT_DIR/$REPORT_NAGIOS
	sed -i -e "1d" $REPORT_TEMP_DIR/$REPORT_TEMP

	echo "<tbody>" >> $REPORT_DIR/$REPORT_NAGIOS
	head -n$((NL-2)) $REPORT_TEMP_DIR/$REPORT_TEMP | sed 's/<TR>/<thead><tr>/g' | sed 's/<TH>/<td>/g' >> $REPORT_DIR/$REPORT_NAGIOS
	echo "</tbody>" >> $REPORT_DIR/$REPORT_NAGIOS

	tail -n1 $REPORT_TEMP_DIR/$REPORT_TEMP | sed 's/<tr>/<tfoot><tr>/g' | sed 's/<\/tr>/<\/tr><\/tfoot>/g' >> $REPORT_DIR/$REPORT_NAGIOS
	echo "</table></div><center>Fecha del reporte:"`date +%d/%m/%Y-%H:%M:%S` "</center></body></html>" >> $REPORT_DIR/$REPORT_NAGIOS
}

getWebReport
prepareReport
createReport

#logger -t "[INFO] Report $REPORT_DIR/$REPORT_NAGIOS done..."
