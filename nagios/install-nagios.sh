#!/bin/bash

USERADD=`which useradd`
GROUPADD=`which groupadd`
USERMOD=`which usermod`
WGET=`which wget`
[ -f /etc/debian_version ] && INSTALL=apt-get || INSTALL=yum

AUTH_FILE=authorized_keys
NAG_SSH_DIR=/home/nagios/.ssh
NAG_KEY_FILE=$NAG_SSH_DIR/$AUTH_FILE
PLUGINS="nagios-plugins-emergya.tar.gz"
#NAG_PLUGINS_URL="http://nagios.emergya.com/recursos/$PLUGINS"
NAG_PLUGINS_URL="https://www.fs.mfernandez.es/$PLUGINS"
KEY="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA0i+3YoBL3jbyc1Tu6eC/H+Ac2BJ499xkD7W3+ubY6AH1jVHh3JzPPpr3E0YOBw1ogd0csWSAdEjRbGDXGG2CiNvTSa8sXZxQvZI1LsHu9EAGIcVYQR8nhT2Bjnas7zaC44/4+FhMn9B8n+xLH2u7dsae0rlpU/fHnw5flt/1j17Siadya6UMjgNeHqc+0YrRVZ5b1WeczNIoFW3bS35T+6cR3hnHKK6+KE/i6vrerGqQHu3mvMJ7L9ftikK0Vic8m1HmmLXjZW6ZcxQ1mU/Ob2cmKijEZQxH3qLzLn03lO7H8e5NKqQWdOh8E15Lx/Iq62Tu30OfgYzKgAAgwVUsyw== nagios@centosNagios"

function check_authorized_keys () {
   if [ ! -d $NAG_SSH_DIR ]; then
      mkdir -p $NAG_SSH_DIR
      touch $NAG_KEY_FILE
      chmod 644 $NAG_KEY_FILE
      echo "$KEY" >> $NAG_KEY_FILE
   else
      if [ ! -f $NAG_KEY_FILE ]; then 
         touch $NAG_KEY_FILE
         chmod 644 $NAG_KEY_FILE
      fi
      grep "$KEY" $NAG_KEY_FILE
      [ $? -eq 1 ] && echo "$KEY" >> $NAG_KEY_FILE
   fi
}

function nagios_user () {
   getent passwd nagios
   [ $? -eq 0 ] && IS_NAG=true || IS_NAG=false
   [ ! $IS_NAG ] && $USERADD -m nagios
   check_authorized_keys
}

function get_plugins () {
   [ -z $WGET ] && $INSTALL install -y wget
   wget --no-check-certificate $NAG_PLUGINS_URL -P /tmp

   tar xzf /tmp/$PLUGINS -C /home/nagios
   chown -R nagios:nagios /home/nagios
   rm -f /tmp/$PLUGINS
}

# Inicio
nagios_user
get_plugins
logger "[INFO] Sucess..."
