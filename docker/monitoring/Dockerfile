# Dockerfile for Nagios and Grafana
FROM ubuntu:14.04
MAINTAINER Manuel Fernandez Panzuela "manuel@mfernandez.es"

# Update and install base software
	RUN apt-get update

# Setting locales
	ENV LANGUAGE en_US.UTF-8
	ENV LANG en_US.UTF-8
	ENV LC_ALL en_US.UTF-8
	RUN locale-gen en_US.UTF-8
	RUN dpkg-reconfigure locales

# Setting virtualhost
	RUN rm /etc/apache2/sites-available/*
	ADD https://github.com/mferpan/devops/....
	RUN ln -s /etc/apache2/sites-available/monitoring.conf

	ADD ./monitoring.conf /etc/apache2/sites-available/
	RUN ln -s /etc/apache2/sites-available/001-docker.conf /etc/apache2/sites-enabled/

# Setting localtime
	RUN cp /usr/share/zoneinfo/Europe/Madrid /etc/localtime
	RUN sed -i 's/\;date\.timezone\ \=/date\.timezone\ \=\ Europe\/Madrid/g' /etc/php5/cli/php.ini
	RUN sed -i 's/\;date\.timezone\ \=/date\.timezone\ \=\ Europe\/Madrid/g' /etc/php5/apache2/php.ini

# Enable mod-rewrite
	RUN a2enmod rewrite

	ENV APACHE_LOG_DIR /var/log/apache2
	ENV APACHE_SERVERADMIN manuel@mfernandez.es
	ENV APACHE_SERVERNAME localhost
	ENV APACHE_DOCUMENTROOT /var/www

	VOLUME ["/docker/nagios", "/"]
	VOLUME ["/docker/nagios", "/"]
	VOLUME ["/docker/nagios", "/"]

#setear la dirección IP del pinfloy
	RUN sed -i 's/nagios@localhost/${NAGIOS_CONTACT_EMAIL}/g' /etc/php5/cli/php.ini
	 

	EXPOSE 80
	CMD ["apache","nagios","influxdb","grafana","collectd"]

	EXPOSE 80
	ADD start.sh /start.sh
	RUN chmod 0755 /start.sh
	CMD ["bash", "start.sh"]