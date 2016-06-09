#!/bin/bash
#
# ISPConfig-Kickstarter (ispckickstarter) v0.6.7-alpha
#
# This is an ISPConfig installer (bash-script) which will make a fully fledged webserver
# out of a fresh debian jessie based linux machine. You can configure it by simple
# replacing some variables in the configuration file and it will run completely unattended.
#
# required packages: locate dnsutils
#
# DO NOT USE THIS IN PRODUCTION ENVIRONMENTS ...unless you know exactly what you are doing!
#
# GNU GENERAL PUBLIC LICENSE Version 2
# Written by stephan.kellermayr@gmail.com
#

# Set plugin-ID
pluginId="ispckickstarter"
# Include installer-library
installerLibrary=./xbi.lib; [ -f ${installerLibrary} ] && . ${installerLibrary} || exit 1



################################################################################
# VARIABLES
#
# Do NOT replace/delete these variables!
# Create a file with the name "ispckickstarter.conf" in the same
# directory instead and change them in this file!
#
################################################################################


# Source-URL for the package-manager, i.e.: "ftp.debian.org"
aptSource=""
# Hostname to use for this installation
hostname=""
# Set IP-address of this server
ipAddress=""
# Default timeserver, i.e.: "at.pool.ntp.org" (http://www.pool.ntp.org/zone/europe)
timeServer=""
# Default web-server if "nginx" and "apache2" are installed
defaultWebServer=""
# Current timezone (http://www.php.net/manual/de/timezones.php)
dateTimeZone=""
# The email-address of the server-admin
systemEmailAddress=""

# Additional packages to install in task "tools"
additionalPackages=""
# Enable dotdeb-repository (default=0) for php7+
dotdebSources=0
# Set innodb_file_per_table to 1
innodb_file_per_table=1
# Version of jailkit (latest version is 2.17)
version_jailkit=""
# DNSBL Realtime blackhole lists
dnsbl=""

# SSL-variables
ssl_bitLength=4096
ssl_days=2555

ssl_countryName=""
ssl_stateOrProvinceName=""
ssl_localityName=""
ssl_organizationName=""
ssl_organizationalUnitName=""
ssl_email=""

# CA-variables
ca_commonName=""
ca_organizationName=""
ca_email=""



## Paths used in this script
path_postfix=/etc/postfix
path_dovecot=/etc/dovecot
path_mysql=/etc/mysql
path_nginx=/etc/php5/fpm
path_apache2=/etc/php5/apache2
path_fail2ban=/etc/fail2ban
path_ssl=/etc/ssl
path_ca=${path_ssl}/ispconfigCA
path_ispconfig=/usr/local/ispconfig
path_ispconfig_ssl=${path_ispconfig}/interface/ssl
path_pureftp_ssl=/etc/ssl/private

# Set default variables (do NOT replace them here! Use them in "ispckickstarter.conf" instead without the "default_" prefix)
default_aptSource="ftp.at.debian.org"
default_hostname=$(hostname -f)
default_ipAddress=$(sed -nr '/address\s*([0-9]{1,3}\.){3}[0-9]{1,3}/p' /etc/network/interfaces | sed 's/\s*address\s*//')
[ "${default_ipAddress}" = "" ] && default_ipAddress=$(dig +short ${default_hostname})
default_timeServer="debian.pool.ntp.org"
default_defaultWebServer="nginx"
default_dateTimeZone=$(cat /etc/timezone)
default_systemEmailAddress="webmaster@$(hostname -d)"

default_ca_countryName=$(echo $LANG | cut -c4,5)
default_ca_stateOrProvinceName=""
default_ca_localityName=""
default_ca_organizationName=$(hostname -d | awk -F'.' '{print $1}' | tr '[:lower:]' '[:upper:]')
default_ca_organizationalUnitName=""
default_ca_commonName="${default_ca_organizationName} Certificate Authority"
default_ca_email=""

default_ssl_countryName=$(echo $LANG | cut -c4,5)
default_ssl_stateOrProvinceName=$(cat /etc/timezone | awk -F'/' '{print $2}')
default_ssl_localityName="${default_ssl_stateOrProvinceName}"
default_ssl_organizationName=${default_ca_organizationName}
default_ssl_organizationalUnitName=$(hostname -s)
default_ssl_commonName="${default_hostname}"
default_ssl_email="${default_systemEmailAddress}"

password_mysql=""
password_mailinglist=""
password_ispconfig=""
password_roundcube=""
password_squirrelmail=""
password_ca=""

# Show passwords in summary
showPasswordsInSummary=1



################################################################################
# TASK CONFIGURATION
################################################################################

# Set available Tasks
tasks=("system" "network" "hostname" "apt" "shell" "ntp" "tools" "rkhunter" "dns" "mysql" "mail" "antispam" "nginx" "ftp" "quota" "mailinglist" "statistic" "monitoring" "phpmyadmin" "roundcube" "squirrelmail" "jailkit" "fail2ban" "ispconfig" "ca" "secure" "postgrey" "spf")

# If enabled, the task will be checked per default in the task-selector
task["system_checked"]=1
task["network_checked"]=1
task["hostname_checked"]=1
task["apt_checked"]=1
task["shell_checked"]=1
task["ntp_checked"]=1
task["tools_checked"]=1
task["rkhunter_checked"]=1
task["dns_checked"]=1
task["mysql_checked"]=1
task["mail_checked"]=1
task["antispam_checked"]=1
task["nginx_checked"]=1
task["apache2_checked"]=0
task["ftp_checked"]=1
task["quota_checked"]=1
task["mailinglist_checked"]=1
task["statistic_checked"]=1
task["monitoring_checked"]=0
task["jailkit_checked"]=1
task["fail2ban_checked"]=1
task["phpmyadmin_checked"]=1
task["roundcube_checked"]=0
task["squirrelmail_checked"]=0
task["ispconfig_checked"]=1
task["ca_checked"]=1
task["secure_checked"]=1
task["postgrey_checked"]=1
task["spf_checked"]=1



################################################################################
# LABELS
################################################################################

#-------------------------------------------------------------------------------
# Labels/Messages [EN]
#-------------------------------------------------------------------------------
label["en_pluginTitle"]="ISPConfig Server-Kickstarter"

label["en_task_system_title"]="Check operating system"
label["en_task_network_title"]="Network configuration"
label["en_task_hostname_title"]="Hostname"
label["en_task_apt_title"]="Systemupdate"
label["en_task_shell_title"]="Reconfiguration of the systemshell"
label["en_task_ntp_title"]="Synchronize system-time"
label["en_task_tools_title"]="Installation of additional tools"
label["en_task_rkhunter_title"]="Rootkithunter"
label["en_task_dns_title"]="DNS-Server"
label["en_task_mysql_title"]="Database-Server"
label["en_task_mail_title"]="Mail-Server"
label["en_task_antispam_title"]="Spamfilter & Antivirus"
label["en_task_nginx_title"]="Web-Server (nginx)"
label["en_task_apache2_title"]="Web-Server (apache2)"
label["en_task_ftp_title"]="FTP-Server"
label["en_task_quota_title"]="Quota"
label["en_task_mailinglist_title"]="Mailinglist"
label["en_task_statistic_title"]="Web-Statistics"
label["en_task_monitoring_title"]="Monitoring"
label["en_task_jailkit_title"]="Jailkit"
label["en_task_fail2ban_title"]="fail2ban"
label["en_task_phpmyadmin_title"]="phpMyAdmin"
label["en_task_roundcube_title"]="Roundcube Webmail (currently not available!)"
label["en_task_squirrelmail_title"]="Squirrelmail Webmail"
label["en_task_ispconfig_title"]="Installation of ISPConfig 3"
label["en_task_ca_title"]="Create own CA"
label["en_task_secure_title"]="Securing the Server"
label["en_task_postgrey_title"]="Mail-Server: delayed delivery with Postgrey"
label["en_task_spf_title"]="Mail-Server: Sender Policy Framework"

#-------------------------------------------------------------------------------
# Labels/Messages [DE]
#-------------------------------------------------------------------------------
label["de_pluginTitle"]="ISPConfig Server-Kickstarter"

label["de_task_system_title"]="Überprüfung des Betriebssystems" # German title of the task
label["de_task_network_title"]="Netzwerkkonfiguration"
label["de_task_hostname_title"]="Hostname"
label["de_task_apt_title"]="Systemupdate"
label["de_task_shell_title"]="Rekonfiguration des Standard-Kommandointerpreter"
label["de_task_ntp_title"]="Systemzeit synchronisieren"
label["de_task_tools_title"]="Installation von zusätzlichen Werkzeugen"
label["de_task_rkhunter_title"]="Rootkithunter"
label["de_task_dns_title"]="DNS-Server"
label["de_task_mysql_title"]="Datenbank-Server"
label["de_task_mail_title"]="Mail-Server"
label["de_task_antispam_title"]="Spamfilter & Virenschutz"
label["de_task_nginx_title"]="Web-Server (nginx)"
label["de_task_apache2_title"]="Web-Server (apache2)"
label["de_task_ftp_title"]="FTP-Server"
label["de_task_quota_title"]="Quota"
label["de_task_mailinglist_title"]="Mailingliste"
label["de_task_statistic_title"]="Web-Statistiken"
label["de_task_monitoring_title"]="Monitoring"
label["de_task_jailkit_title"]="Jailkit"
label["de_task_fail2ban_title"]="fail2ban"
label["de_task_phpmyadmin_title"]="phpMyAdmin"
label["de_task_roundcube_title"]="Roundcube Webmail (currently not available!)"
label["de_task_squirrelmail_title"]="Squirrelmail Webmail"
label["de_task_ispconfig_title"]="Installation von ISPConfig 3"
label["de_task_ca_title"]="Eigene CA erstellen"
label["de_task_secure_title"]="Absichern des Servers"
label["de_task_postgrey_title"]="Mail-Server: Zustellverzögerung mittels Postgrey"
label["de_task_spf_title"]="Mail-Server: Sender Policy Framework"



label["de_dialog_welcome_title"]="ISPConfig Kickstarter"
label["de_dialog_welcome_message"]="Willkommen beim Installationstool für ISPConfig\n\nBitte stellen Sie vor der Installation sicher, dass das Netzwerk korrekt konfiguriert ist \n\nWenn Sie sich sicher sind, und das Installations-Script weiter ausführen möchten, wählen Sie <Weiter>."

label["de_dialog_aptSource_title"]="Paketquelle"
label["de_dialog_aptSource_message"]="Bitte geben Sie die zu verwendende Paketquelle an, z.B. \"ftp.at.debian.org\""
label["de_dialog_hostname_title"]="Hostname"
label["de_dialog_hostname_message"]="Bitte geben Sie den Hostnamen (FQDN) des Servers ein, z.B. \"srv1.beispiel.at\""
label["de_dialog_ipAddress_title"]="IP-Adresse"
label["de_dialog_ipAddress_message"]="Bitte geben Sie die IP-Adresse des Servers ein"
label["de_dialog_timeServer_title"]="Zeit-Server"
label["de_dialog_timeServer_message"]="Bitte geben Sie einen Server an, von welchem die aktuelle Uhrzeit bezogen werden soll"
label["de_dialog_defaultWebServer_title"]="Web-Server"
label["de_dialog_defaultWebServer_message"]="Bitte wählen Sie den Web-Server der primär verwendet werden soll"
label["de_dialog_dateTimeZone_title"]="PHP Zeitzone"
label["de_dialog_dateTimeZone_message"]="Bitte wählen Sie eine Zeitzone für PHP (http://www.php.net/manual/de/timezones.php)"
label["de_dialog_systemEmailAddress_title"]="Administrator E-Mail"
label["de_dialog_systemEmailAddress_message"]="Bitte geben Sie die E-Mailadresse des administrativen Benutzers dieses Servers ein"

label["de_dialog_ca_countryName_title"]="CA: Land"
label["de_dialog_ca_countryName_message"]="Bitte geben Sie den (zweistelligen) ISO-code Ihres Landes ein.\n(Wird für die CA benötigt und darf nicht leer sein!)"
label["de_dialog_ca_commonName_title"]="CA: Zertifikatsaussteller"
label["de_dialog_ca_commonName_message"]="Bitte geben Sie den Namen der CA ein."
label["de_dialog_ca_organizationName_title"]="CA: Zertifikatsaussteller"
label["de_dialog_ca_organizationName_message"]="Bitte geben Sie den Namen der Origanisation der CA ein."

label["de_dialog_ssl_countryName_title"]="SSL: Land"
label["de_dialog_ssl_countryName_message"]="Bitte geben Sie den (zweistelligen) ISO-code Ihres Landes ein.\n(Wird für das Generieren der Zertifikate benötigt und darf nicht leer sein!)"
label["de_dialog_ssl_stateOrProvinceName_title"]="SSL: Bundesland"
label["de_dialog_ssl_stateOrProvinceName_message"]="Bitte geben Sie den Namen Ihres Bundeslandes ein.\n(Wird für das Generieren der Zertifikate benötigt und darf nicht leer sein!)"
label["de_dialog_ssl_localityName_title"]="SSL: Stadt"
label["de_dialog_ssl_localityName_message"]="Bitte geben Sie den Namen Ihrer Stadt ein.\n(Wird für das Generieren der Zertifikate benötigt und darf nicht leer sein!)"
label["de_dialog_ssl_organizationName_title"]="SSL: Organisation"
label["de_dialog_ssl_organizationName_message"]="Bitte geben Sie den Namen Ihrer Organisation ein.\n(Wird für das Generieren der Zertifikate benötigt und darf nicht leer sein!)"
label["de_dialog_ssl_organizationalUnitName_title"]="SSL: Abteilung"
label["de_dialog_ssl_organizationalUnitName_message"]="Bitte geben Sie den Namen der Abteilung ein.\n(Wird für das Generieren der Zertifikate benötigt und darf nicht leer sein!)"
label["de_dialog_ssl_commonName_title"]="SSL: Servername"
label["de_dialog_ssl_commonName_message"]="Bitte geben Sie den Hostnamen des Zertifikats an.\n(Dieser Wert muss mit dem Hostnamen des Server übereinstimmen!)"
label["de_dialog_ssl_email_title"]="SSL: E-Mail"
label["de_dialog_ssl_email_message"]="Bitte geben Sie die E-Mail des Zertifikatsinhaber an.\n(Wird für das Generieren der Zertifikate benötigt und darf nicht leer sein!)"

label["de_dialog_password_mysql_title"]="Konfiguriere Datenbank-Server"
label["de_dialog_password_mysql_message"]="Neues Passwort für den MySQL-»root«-Benutzer:\n(KEINE Sonderzeichen oder Leerzeichen!)"
label["de_dialog_password_mysql_repeat_message"]="Wiederholen Sie das Passwort für den MySQL-»root«-Benutzer:"
label["de_dialog_password_ispconfig_title"]="ISPConfig: Admin-Passwort"
label["de_dialog_password_ispconfig_message"]="Bitte geben Sie ein Passwort für den administrativen Benutzer von ISPConfig ein.\n(KEINE Sonderzeichen oder Leerzeichen!)"
label["de_dialog_password_ispconfig_repeat_message"]="Bitte wiederholen Sie das Passwort für den administrativen Benutzer von ISPConfig"
label["de_dialog_password_roundcube_title"]="Roundcube: Admin-Passwort"
label["de_dialog_password_roundcube_message"]="Bitte geben Sie ein Passwort für den administrativen Benutzer von Roundcube ein.\n(KEINE Sonderzeichen oder Leerzeichen!)"
label["de_dialog_password_roundcube_repeat_message"]="Bitte wiederholen Sie das Passwort für den administrativen Benutzer von Roundcube"
label["de_dialog_password_mailinglist_title"]="Mailingliste: Admin-Passwort"
label["de_dialog_password_mailinglist_message"]="Bitte geben Sie ein Passwort für den administrativen Benutzer der Mailingliste ein.\n(KEINE Sonderzeichen oder Leerzeichen!)"
label["de_dialog_password_mailinglist_repeat_message"]="Bitte wiederholen Sie das Passwort für den administrativen Benutzer der Mailingliste"
label["de_dialog_password_ca_title"]="CA Passwort"
label["de_dialog_password_ca_message"]="Bitte geben Sie ein Passwort für die CA ein.\n(KEINE Sonderzeichen oder Leerzeichen!)"
label["de_dialog_password_ca_repeat_message"]="Bitte wiederholen Sie das Passwort für die CA"

label["de_password_mysql"]="Passwort für den MySQL-»root«-Benutzer:"
label["de_password_roundcube"]="Roundcube Admin-Passwort:"
label["de_password_squirrelmail"]="Squirrelmail Admin-Passwort:"
label["de_password_mailinglist"]="Mailingliste Admin-Passwort:"
label["de_password_ispconfig"]="ISPConfig Admin-Passwort:"
label["de_password_ca"]="CA Passwort:"



label["de_view_title_common"]="Allgemeine Informationen:"
label["de_view_title_ca"]="CA-Informationen:"
label["de_view_title_ssl"]="SSL-Informationen:"
label["de_view_title_passwords"]="Passwörter:"

label["de_var_aptSource"]="Paket-Quelle"
label["de_var_hostname"]="Hostname"
label["de_var_ipAddress"]="IP-Adresse"
label["de_var_timeServer"]="Zeit-Server"
label["de_var_defaultWebServer"]="Webserver"
label["de_var_dateTimeZone"]="Zeitzone"
label["de_var_systemEmailAddress"]="System-E-Mail"

label["de_var_ca_countryName"]="Land (C)"
label["de_var_ca_stateOrProvinceName"]="Bundesland (ST)"
label["de_var_ca_localityName"]="Stadt (L)"
label["de_var_ca_organizationName"]="Organisation (O)"
label["de_var_ca_organizationalUnitName"]="Abteilung (OU)"
label["de_var_ca_commonName"]="Allgemeiner Name (CN)"
label["de_var_ca_email"]="E-Mail"

label["de_var_ssl_countryName"]="Land (C)"
label["de_var_ssl_stateOrProvinceName"]="Bundesland (ST)"
label["de_var_ssl_localityName"]="Stadt (L)"
label["de_var_ssl_organizationName"]="Organisation (O)"
label["de_var_ssl_organizationalUnitName"]="Abteilung (OU)"
label["de_var_ssl_commonName"]="Allgemeiner Name (CN)"
label["de_var_ssl_email"]="E-Mail"

label["de_var_password_mysql"]="MySQL"
label["de_var_password_ispconfig"]="ISPConfig"
label["de_var_password_roundcube"]="Roundcube"
label["de_var_password_mailinglist"]="Mailman"
label["de_var_password_ca"]="SSL-CA"




################################################################################
# TASK Functions
################################################################################

#-------------------------------------------------------------------------------
# TASK: Operatingsystem
# TODO: Check language and run dpkg-reconfigure locales: echo $LANGUAGE | awk -F':' '{print $2}' ...
#-------------------------------------------------------------------------------
label["de_task_system_queue_updatedb"]="Erneuere Datenbank für locate"
label["de_task_system_queue_fixdb"]="Überprüfe Konsistenz der debconf-Datenbank"

label["en_task_system_queue_updatedb"]="Regenerate database for locate"
label["en_task_system_queue_fixdb"]="Check consistency of debconf-database"

function task_system() {
	xbi_hook init

	# Silently disable sources from CD/DVD if set
	sed -i 's/^deb cdrom/#deb cdrom/g' /etc/apt/sources.list

	# Install debconf-utils for predefined answers when using apt-get
	xbi_package install "locate debconf-utils"

	# Maintenance: Regenerate database for locate/mlocate
	xbi_cmd "updatedb" "$(xbi_label task_system_queue_updatedb)"

	# Check consistency of debconf-database
	xbi_cmd "/usr/share/debconf/fix_db.pl" "$(xbi_label task_system_queue_fixdb)"

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Network configuration
#-------------------------------------------------------------------------------
label["de_task_network_fail"]="Netzwerkkonfiguration fehlerhaft. Bitte prüfen Sie \"/etc/network/interfaces\" und vergewissern Sie sich, dass eine statische IP-Adresse verwendet wird."

label["en_task_network_fail"]="Network misconfiguration. Please take a look at \"/etc/network/interfaces\" and check the IP-address."

function task_network() {
	xbi_hook init

	# Check network-interfaces for a static IP-address and verify that the given IP is the one which we can find there
	# Example configuration for static IP-address in /etc/network/interfaces:
	# auto eth0
	# iface eth0 inet static
	#   address 192.168.1.XX
	#   netmask 255.255.255.0
	#   network 192.168.1.0
	#   broadcast 192.168.1.255
	#   gateway 192.168.1.1
	if
		[ $(grep "^iface eth. inet static" /etc/network/interfaces | wc -l) -lt 1 ] ||
		[ $(grep "address\s${ipAddress}" /etc/network/interfaces | wc -l) -lt 1 ];
	then
		xbi_fail "$(xbi_label task_network_fail)"
	fi

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Hostname
#-------------------------------------------------------------------------------
label["de_task_hostname_queue_setHostname"]="Setze Hostname: ###"
label["de_task_hostname_queue_emptyBuffer"]="Leere Dateisystem-Buffer"
label["de_task_hostname_queue_hosts"]="Ersetze IP-Adresse/Hostname in /etc/hosts"
label["de_task_hostname_queue_test"]="Prüfe Konfiguration"
label["de_task_hostname_queue_test_ok"]="Konfiguration geprüft"
label["de_task_hostname_queue_test_fail"]="Der Hostname des Systems ist nicht korrekt konfiguriert. Bitte prüfen Sie \"/etc/hosts\" auf etwaige Fehler."

label["en_task_hostname_queue_setHostname"]="Set hostname: ###"
label["en_task_hostname_queue_emptyBuffer"]="Empty filesystem-buffer"
label["en_task_hostname_queue_hosts"]="Replace IP-addresse/hostname in /etc/hosts"
label["en_task_hostname_queue_test"]="Test configuration"
label["en_task_hostname_queue_test_ok"]="Configuration tested"
label["en_task_hostname_queue_test_fail"]="Hostname could not be set. Please inspect \"/etc/hosts\"."

function task_hostname() {
	xbi_hook init

	# Set new hostname/mailname
	xbi_cmdQueue "echo ${hostname} >/etc/hostname"
	xbi_cmdQueue "echo ${hostname} >/etc/mailname"
	xbi_cmdQueueExec setHostname "${hostname}"

	# Empty filesystem-buffer
	xbi_cmd "sync" "$(xbi_label task_hostname_queue_emptyBuffer)"

	# Enable new hostname
	xbi_cmd "sysctl kernel.hostname=${hostname}"

	# Backup original file
	xbi_backup "/etc/hosts" "~"

	# Replace default values with ipaddress and hostname
	# TODO: Replace with real IP-address
	xbi_cmd "sed -i \"s/^127\.0\.1\.1.*/${ipAddress}\t${hostname}\t$(hostname -s)/g\" /etc/hosts" \
		"$(xbi_label task_hostname_queue_hosts)"

	# Test configuration
	xbi_cmdQueue "[ \"$(hostname)\" = \"$(hostname -f)\" ]"
	xbi_cmdQueue "[ \"$(hostname -i)\" = \"${ipAddress}\" ]"
	xbi_cmdQueueExec test

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Systemupdate
# TODO Ping Host, check if source is available (could not be tested in virtualbox-environment)
#-------------------------------------------------------------------------------
label["de_task_apt_queue_repository"]="Ersetze apt-Quelle"
label["de_task_apt_queue_repository_ok"]="Ersetze apt-Quelle: ###"
label["de_task_apt_queue_repository_fail"]="Quelle ### konnte nicht eingerichtet werden"
label["de_task_apt_queue_source"]="Füge \"main\" und \"contrib\" der Quelle hinzu"
label["de_task_apt_queue_dotdeb"]="Importiere dotdeb.org"

label["en_task_apt_queue_repository"]="Replace apt-source"
label["en_task_apt_queue_repository_ok"]="Replace apt-source: ###"
label["en_task_apt_queue_repository_fail"]="Source ### could not be added"
label["en_task_apt_queue_source"]="Add \"main\" and \"contrib\" to the source"
label["en_task_apt_queue_dotdeb"]="Import dotdeb.org"

function task_apt() {
	xbi_hook init

	# Replace apt-source (test included)
	xbi_cmdQueue "sed -i \"s/^\(.*http:\/\/\)\(.*\)\(\/debian.*\)/\1${aptSource}\3/\" /etc/apt/sources.list"
	xbi_cmdQueue "[ \$(sed -n -e \"s/^\(.*http:\/\/\)\(${aptSource}\)\(\/debian.*\)/\2/p\" /etc/apt/sources.list | wc -l) -ge 4 ]"
	xbi_cmdQueueExec repository "${aptSource}"

	# Add "main" and "contrib" to the source (test included)
	xbi_cmdQueue "sed -i 's/jessie main$/jessie main contrib non-free/g' /etc/apt/sources.list"
	xbi_cmdQueue "sed -i 's/jessie-updates main$/jessie-updates main contrib non-free/g' /etc/apt/sources.list"
	xbi_cmdQueue "sed -i 's/jessie\/updates main$/jessie\/updates main contrib non-free/g' /etc/apt/sources.list"
	xbi_cmdQueue "[ \$(sed -n -e \"/deb\(-src\)*.*jessie[-\/]*\(updates\)* main contrib non-free/p\" /etc/apt/sources.list | wc -l) -ge 6 ]"
	xbi_cmdQueueExec source

	# Include dotdeb.org
	if [ $dotdebSources -eq 1 ]; then
		xbi_cmdQueue "echo -e \"deb http://packages.dotdeb.org jessie all\ndeb-src http://packages.dotdeb.org jessie all\" >/etc/apt/sources.list.d/dotdeb.list"
		xbi_cmdQueue "wget https://www.dotdeb.org/dotdeb.gpg -O /tmp/dotdeb.gpg && apt-key add /tmp/dotdeb.gpg"
		xbi_cmdQueueExec dotdeb
	fi

	# Update/upgrade
	xbi_package update
	xbi_package upgrade

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Reconfiguration of the Systemshell
#-------------------------------------------------------------------------------
function task_shell() {
	xbi_hook init

	debconf-set-selections <<< "dash dash/sh boolean false"
	xbi_cmd "dpkg-reconfigure -f noninteractive dash"

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Synchronize system-time
# TODO: Check if timeserver is reachable
#-------------------------------------------------------------------------------
label["de_task_ntp_queue_server"]="Ersetze Zeitserver mit: ###"
label["de_task_ntp_queue_secure"]="Absichern von ntp"
label["de_task_ntp_queue_update"]="Aktualisiere Zeit vom Server"

label["en_task_ntp_queue_server"]="Replace timeserver with: ###"
label["en_task_ntp_queue_secure"]="Securing ntp"
label["en_task_ntp_queue_update"]="Update time from server"

function task_ntp() {
	xbi_hook init

	# Install Packages
	xbi_package install "ntp ntpdate"

	# Replace default-timeserver
	if [ "${timeServer}" != "" ]; then
		xbi_cmd "sed -i \"s/^\(server [0-9]*\.\)\(.*\)\( iburst\)/\1${timeServer}\3/g\" /etc/ntp.conf" \
			"$(xbi_labelReplaced task_ntp_queue_server ${timeServer})"
	fi

	# Default policy prevents queries 
	# http://support.ntp.org/bin/view/Main/SecurityNotice#DRDoS_Amplification_Attack_using
	xbi_cmd "grep \"^restrict default nopeer nomodify notrap noquery\" /etc/ntp.conf || echo -e \"# Default policy prevents queries\nrestrict default nopeer nomodify notrap noquery\" >>/etc/ntp.conf" \
		"$(xbi_label task_ntp_queue_secure)"

	# Restart timeserver
	xbi_package restart "ntp"

	# Update time from server
	xbi_cmd "ntpdate -q ${timeServer}" \
		"$(xbi_labelReplaced task_ntp_queue_update)"

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Installation of additional tools
#-------------------------------------------------------------------------------
function task_tools() {
	xbi_hook init

	# Install Packages
	xbi_package install "ssh openssh-server openssl sudo binutils ssl-cert mcrypt git rsync ${additionalPackages}"

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Rootkithunter
#-------------------------------------------------------------------------------
function task_rkhunter() {
	xbi_hook init

	# Install Packages
	xbi_package install "rkhunter"

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: DNS-Server
#-------------------------------------------------------------------------------
function task_dns() {
	xbi_hook init

	# Install Packages
	xbi_package install "bind9 dnsutils"

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Database-Server
#-------------------------------------------------------------------------------
label["de_task_mysql_connection_fail"]="Konnte nicht zu mysql verbinden"
label["de_task_mysql_queue_innodb"]="Aktiviere \"innodb_file_per_table\""
label["de_task_mysql_queue_test"]="Prüfe Konfiguration"

label["en_task_mysql_connection_fail"]="Failed to connect to mysql"
label["en_task_mysql_queue_innodb"]="Enable \"innodb_file_per_table\""
label["en_task_mysql_queue_test"]="Check configuration"

function task_mysql() {
	xbi_hook init

	# Preconfiguration for unattended installation
	debconf-set-selections <<< "mysql-server-5.1 mysql-server/root_password password ${password_mysql}"
	debconf-set-selections <<< "mysql-server-5.1 mysql-server/root_password_again password ${password_mysql}"

	# Install packages for mysql-database
	xbi_package install "mysql-client mysql-server"

	# Create backup of original configuration-file
	xbi_backup "${path_mysql}/my.cnf" ".dpkg"

	# Mysql should listen on *.*
	xbi_confMod comment 1 ${path_mysql}/my.cnf "bind-address"

	# TODO: Check connection
	#until mysql -u root -p$password_mysql  -e ";" ; do
	#	read -p "Can't connect, please retry: " password_mysql
	#done

	if mysql -p${password_mysql} -u root -e ";" 2>/dev/null; then
		# Enable "innodb_file_per_table" (test included)
		if [ ${innodb_file_per_table} -eq 1 ] && [ $(mysql -p${password_mysql} -u root -e"SHOW VARIABLES LIKE '%innodb_file_per_table%';" 2>/dev/null | grep "ON" | wc -l) -eq 0 ]; then
			xbi_cmdQueue "echo -e \"[mysqld]\ninnodb_file_per_table = 1\" >>${path_mysql}/conf.d/custom-tweaks.cnf" null
			xbi_cmdQueue "service mysql restart" all
			# Using "--password=" instead of "-p", because 'sed' does not recognize word-boundaries when stripping passwords from logfile!
			xbi_cmdQueue "[ \$(mysql --password=${password_mysql} -u root -e\"SHOW VARIABLES LIKE '%innodb_file_per_table%';\" 2>>${logFile} | grep \"ON\" | wc -l) -eq 1 ]" err
			xbi_cmdQueueExec innodb
		fi
	else
		xbi_fail "$(xbi_label connection_fail)"
	fi

	# Restart database-server
	xbi_package restart "mysql"

	xbi_cmdQueue "[ \$(netstat -tap | grep \"\*:mysql\" | wc -l) -gt 0 ]"
	xbi_cmdQueueExec test

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Mail-Server
#-------------------------------------------------------------------------------
label["de_task_mail_queue_tls"]="Aktiviere Port 465 (smtps)"
label["de_task_mail_queue_test"]="Teste Port 465"

label["en_task_mail_queue_tls"]="Enable port 465 (smtps)"
label["en_task_mail_queue_test"]="Test port 465"

function task_mail() {
	xbi_hook init

	# Purge exim4
	xbi_package remove "exim4 exim4-base exim4-config exim4-daemon-light"

	# Preconfiguration for unattended installation
	debconf-set-selections <<< "postfix postfix/mailname string ${hostname}"
	debconf-set-selections <<< "postfix postfix/destinations string ${hostname}, localhost, localhost.localdomain"
	debconf-set-selections <<< "postfix postfix/main_mailer_type select Internet Site"

	# Install postfix and friends
	xbi_package install "postfix postfix-mysql postfix-pcre postfix-doc getmail4 dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve"

	# Backup configuration files
	xbi_backup "${path_postfix}/master.cf" ".dpkg"
	xbi_backup "${path_postfix}/main.cf" ".dpkg"
	xbi_backup "${path_dovecot}/dovecot.conf" ".dpkg"

	# Uncomment smtps-params in master.cf
	xbi_cmdQueue "$(xbi_confMod uncomment 0 ${path_postfix}/master.cf 'submission')"
	xbi_cmdQueue "$(xbi_confMod uncomment 0 ${path_postfix}/master.cf 'smtps')"
	xbi_cmdQueue "$(xbi_confMod uncomment 0 ${path_postfix}/master.cf '  -o syslog_name')"
	xbi_cmdQueue "$(xbi_confMod uncomment 0 ${path_postfix}/master.cf '  -o smtpd_tls_security_level')"
	xbi_cmdQueue "$(xbi_confMod uncomment 0 ${path_postfix}/master.cf '  -o smtpd_sasl_auth_enable')"
	xbi_cmdQueue "$(xbi_confMod uncomment 0 ${path_postfix}/master.cf '  -o smtpd_client_restrictions')"
	xbi_cmdQueue "$(xbi_confMod uncomment 0 ${path_postfix}/master.cf '  -o smtpd_tls_wrappermode')"
	xbi_cmdQueue "$(xbi_confMod setValue 0 ${path_postfix}/main.cf mua_client_restrictions permit_sasl_authenticated,reject)"
	xbi_cmdQueueExec tls

	# Restart postfix
	xbi_package restart "postfix"

	# Test TLS
	xbi_cmdQueue "{ echo quit; } | openssl s_client -connect ${hostname}:465" err
	xbi_cmdQueueExec test

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Mail-Server: Spamfilter & Antivirus
# TODO: Check if filter is working
#-------------------------------------------------------------------------------
function task_antispam() {
	xbi_hook init

	# Install Packages
	xbi_package install "amavisd-new apt-listchanges arj cabextract daemon clamav clamav-docs clamav-daemon libauthen-sasl-perl libnet-ldap-perl lzop nomarch p7zip spamassassin libnet-dns-perl libio-socket-ssl-perl libnet-ident-perl libio-string-perl unrar-free zoo unzip bzip2 zip"

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Web-Server (nginx)
#-------------------------------------------------------------------------------
label["de_task_nginx_queue_cgifix"]="Setze \"cgi.fix_pathinfo\" auf \"0\""
label["de_task_nginx_queue_timezone"]="Setze \"date.timezone\" auf \"###\""
label["de_task_nginx_queue_proc"]="Konfiguriere nginx für ### Prozessorkerne"

label["en_task_nginx_queue_cgifix"]="Set \"cgi.fix_pathinfo\" to \"0\""
label["en_task_nginx_queue_timezone"]="Set \"date.timezone\" to \"###\""
label["en_task_nginx_queue_proc"]="Configure nginx for ### CPU-cores"

function task_nginx() {
	xbi_hook init

	# php5-apcu is only available in PHP 5.5.x
	local additionalPackages=""
	xbi_isAvailable "php5-apcu" && additionalPackages="php5-apcu" || additionalPackages="php-apc"

	# Install packages
	xbi_package install "fcgiwrap memcached mcrypt nginx php5-curl php5-fpm php5-gd php5-imagick php5-imap php5-intl php5-mcrypt php5-memcache php5-memcached php5-mysql php5-cli php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl php-auth php-pear ${additionalPackages}"

	xbi_backup "${path_nginx}/php.ini" ".dpkg"

	# Disable cgi.fix_pathinfo
	xbi_cmdQueue "$(xbi_iniMod uncomment 0 ${path_nginx}/php.ini 'PHP' 'cgi.fix_pathinfo' ';')"
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_nginx}/php.ini 'PHP' 'cgi.fix_pathinfo' '0')"
	xbi_cmdQueueExec cgifix

	# Set correct date/timezone
	xbi_cmdQueue "$(xbi_iniMod uncomment 0 ${path_nginx}/php.ini 'Date' 'date.timezone' ';')"
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_nginx}/php.ini 'Date' 'date.timezone' \\\"${dateTimeZone}\\\")"
	xbi_cmdQueueExec timezone "${dateTimeZone}"

	# Determine the amount of available processors
	local nproc="$(nproc)"
	xbi_cmdQueue "$(xbi_confMod setValue 0 /etc/nginx/nginx.conf worker_processes ${nproc}\;)"
	xbi_cmdQueueExec proc "${nproc}"

	# Restart the web-server
	xbi_package restart "php5-fpm"
	xbi_package restart "fcgiwrap"

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Web-Server (apache2)
#-------------------------------------------------------------------------------
label["de_task_apache2_queue_modules"]="Aktiviere Apache-Module"
label["de_task_apache2_queue_timezone"]="Setze \"date.timezone\" auf \"###\""

label["en_task_apache2_queue_modules"]="Enable apache-modules"
label["en_task_apache2_queue_timezone"]="Set \"date.timezone\" to \"###\""

function task_apache2() {
	xbi_hook init

	# php5-apcu is only available in PHP 5.5.x
	local additionalPackages=""
	xbi_isAvailable "php5-apcu" && additionalPackages="php5-apcu" || additionalPackages="php-apc"

	# Install packages
	xbi_package install "apache2 apache2.2-common apache2-doc apache2-mpm-prefork apache2-suexec apache2-utils libapache2-mod-fcgid libapache2-mod-php5 libapache2-mod-python libexpat1 libruby mcrypt memcached php5 php5-cgi php5-cli php5-common php5-curl php5-gd php5-imagick php5-imap php5-intl php5-mcrypt php5-memcache php5-memcached php5-mysql php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl php-auth php-pear libapache2-mod-fastcgi php5-fpm ${additionalPackages}"

	# Enable apache-modules
	xbi_cmd "a2enmod suexec rewrite ssl actions include dav_fs dav auth_digest actions fastcgi alias" \
		"$(xbi_label task_apache2_queue_modules)"

	xbi_backup "${path_apache2}/php.ini" ".dpkg"

	# Set correct date/timezone
	xbi_cmdQueue "$(xbi_iniMod uncomment 0 ${path_apache2}/php.ini 'Date' 'date.timezone' ';')"
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_apache2}/php.ini 'Date' 'date.timezone' \\\"${dateTimeZone}\\\")"
	xbi_cmdQueueExec timezone "${dateTimeZone}"

	# Restart the web-server
	xbi_package restart "apache2"

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: FTP-Server
#-------------------------------------------------------------------------------
label["de_task_ftp_queue_configure"]="Konfiguriere FTP-Server"
label["de_task_ftp_queue_cert"]="Erzeuge SSL-Zertifikat und aktiviere TLS"
label["de_task_ftp_queue_test"]="Verbindungstest"
label["de_task_ftp_queue_test_ok"]="Sichere Verbindung zu ### erfolgreich hergestellt"
label["de_task_ftp_queue_test_fail"]="Sichere Verbindung zu ### fehlgeschlagen"

label["en_task_ftp_queue_configure"]="Configure FTP-server"
label["en_task_ftp_queue_cert"]="Generate SSL-certificate and enable TLS"
label["en_task_ftp_queue_test"]="Connection-test"
label["en_task_ftp_queue_test_ok"]="Secure connection to ### succesfully established"
label["en_task_ftp_queue_test_fail"]="Secure connection to ### failed"

function task_ftp() {
	xbi_hook init

	# Install FTP-server packages
	xbi_package install "pure-ftpd-common pure-ftpd-mysql"

	# Configure FTP-server
	xbi_cmdQueue "$(xbi_confMod setValue 0 /etc/default/pure-ftpd-common 'STANDALONE_OR_INETD' 'standalone')"
	xbi_cmdQueue "$(xbi_confMod setValue 0 /etc/default/pure-ftpd-common 'VIRTUALCHROOT' 'true')"
	xbi_cmdQueueExec configure

	# Generate SSL-certificate and enable secure connections
	local sslSubj="/C=${ssl_countryName}/ST=${ssl_stateOrProvinceName}/L=${ssl_localityName}/O=${ssl_organizationName}/OU=${ssl_organizationalUnitName}/CN=${ssl_commonName}/emailAddress=${ssl_email}"
	xbi_cmdQueue "mkdir -p ${path_pureftp_ssl}/"
	xbi_cmdQueue "openssl req -subj \"${sslSubj}\" -x509 -newkey rsa:${ssl_bitLength} -nodes -days ${ssl_days} -keyout ${path_pureftp_ssl}/pure-ftpd.pem -out ${path_pureftp_ssl}/pure-ftpd.pem" err
	xbi_cmdQueue "chmod 600 ${path_pureftp_ssl}/pure-ftpd.pem"
	xbi_cmdQueue "echo 2 >/etc/pure-ftpd/conf/TLS"
	xbi_cmdQueueExec cert

	# Restart FTP-server
	xbi_package restart "pure-ftpd-mysql"

	# Test secure connection
	xbi_cmdQueue "{ echo quit; } | openssl s_client -connect ${hostname}:21 -starttls ftp" err
	xbi_cmdQueueExec test ${hostname}

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Quota
#-------------------------------------------------------------------------------
label["de_task_quota_queue_configure"]="Konfiguriere Quota"
label["de_task_quota_queue_addquota"]="Versuche Quota in /etc/fstab einzubinden"
label["de_task_quota_queue_addquota_ok"]="Quota erfolgreich in /etc/fstab eingebunden"
label["de_task_quota_queue_addquota_fail"]="Fehler beim einbinden von Quota in /etc/fstab"
label["de_task_quota_queue_addquota_log"]="/etc/fstab konnte nicht erfolgreich modifiziert werden"
label["de_task_quota_queue_quotacheck"]="Aktiviere Quota"

label["en_task_quota_queue_configure"]="Configure quota"
label["en_task_quota_queue_addquota"]="Try to set quota in /etc/fstab"
label["en_task_quota_queue_addquota_ok"]="Quota succesfully set in /etc/fstab"
label["en_task_quota_queue_addquota_fail"]="Failed when trying to set quota in /etc/fstab"
label["en_task_quota_queue_addquota_log"]="/etc/fstab could not be succesfully complemented"
label["en_task_quota_queue_quotacheck"]="Enable quota"

function task_quota() {
	xbi_hook init

	# Install quota
	xbi_package install "quota quotatool"

	# Check if quota is already enabled
	if [ $(mount | grep "on / " | egrep "usrjquota|grpjquota" | wc -l) -eq 0 ]; then
		# Manually backup /etc/fstab
		cp -p /etc/fstab /etc/fstab~
		# Replace content in /etc/fstab, remount and softfail if remount fails
		xbi_cmdQueue "sed -i 's/errors=remount-ro /errors=remount-ro,usrjquota=quota.user,grpjquota=quota.group,jqfmt=vfsv0 /g' /etc/fstab"
		xbi_cmdQueue "mount -o remount /" null
		xbi_cmdQueueExec addquota
		local exitCode=$?
		# Remount failed, restore /etc/fstab and exit
		if [ ${exitCode} -eq 1 ]; then
			mv /etc/fstab~ /etc/fstab
			xbi_fail "$(xbi_label task_quota_queue_addquota_log)"
		else
			xbi_cmdQueue "quotacheck -avugm"
			xbi_cmdQueue "quotaon -avug"
			xbi_cmdQueueExec quotacheck
		fi
		xbi_package restart "pure-ftpd-mysql"
	fi

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Mailinglist
# TODO: Check if nginx and/or apache is installed
# TODO: Add nginx/apache-directives
#-------------------------------------------------------------------------------
label["de_task_mailinglist_queue_configure"]="Konfiguriere Mailingliste"
label["de_task_mailinglist_queue_newlist"]="Erstelle Liste \"mailman\""
label["de_task_mailinglist_queue_newlist_ok"]="Mailingliste \"mailman\" wurde erstellt"
label["de_task_mailinglist_queue_newlist_fail"]="Fehler beim Erstellen der Liste \"mailman\""
label["de_task_mailinglist_queue_aliases"]="Füge Einträge für mailman zu /etc/aliases hinzu"

label["en_task_mailinglist_queue_configure"]="Configure mailinglist"
label["en_task_mailinglist_queue_newlist"]="Create new list \"mailman\""
label["en_task_mailinglist_queue_newlist_ok"]="Mailinglist \"mailman\" succesfully created"
label["en_task_mailinglist_queue_newlist_fail"]="List \"mailman\" could not be created succesfully"
label["en_task_mailinglist_queue_aliases"]="Add records for mailman to /etc/aliases"

function task_mailinglist() {
	xbi_hook init

	# Preconfiguration for unattended installation
	local multiselectLanguage="en"
	[ "${installerLanguage}" != "en" ] && multiselectLanguage="${installerLanguage},en"
	debconf-set-selections <<< "mailman mailman/default_server_language select ${installerLanguage}"
	debconf-set-selections <<< "mailman mailman/site_languages multiselect ${multiselectLanguage}"
	debconf-set-selections <<< "mailman mailman/used_languages string ${installerLanguage}"

	# Install mailinglist
	xbi_package install "mailman"

	# Remove any existing lists and recreate default mailinglist "mailman"
	xbi_cmdQueue "rmlist -a mailman" err
	xbi_cmdQueue "newlist -q -l de mailman ${systemEmailAddress} ${password_mailinglist}" err
	xbi_cmdQueueExec newlist

	# Add mailman-aliases to /etc/aliases and reload the alias database
	if [ $(grep "mailman" /etc/aliases | wc -l) -eq 0 ]; then
		xbi_cmdQueue "echo '
## mailman Mailingliste
mailman:              \"|/var/lib/mailman/mail/mailman post mailman\"
mailman-admin:        \"|/var/lib/mailman/mail/mailman admin mailman\"
mailman-bounces:      \"|/var/lib/mailman/mail/mailman bounces mailman\"
mailman-confirm:      \"|/var/lib/mailman/mail/mailman confirm mailman\"
mailman-join:         \"|/var/lib/mailman/mail/mailman join mailman\"
mailman-leave:        \"|/var/lib/mailman/mail/mailman leave mailman\"
mailman-owner:        \"|/var/lib/mailman/mail/mailman owner mailman\"
mailman-request:      \"|/var/lib/mailman/mail/mailman request mailman\"
mailman-subscribe:    \"|/var/lib/mailman/mail/mailman subscribe mailman\"
mailman-unsubscribe:  \"|/var/lib/mailman/mail/mailman unsubscribe mailman\"' >>/etc/aliases"
		xbi_cmdQueue "newaliases"
		xbi_cmdQueueExec aliases
	fi

	xbi_hook post

	# Restart postfix
	[ $(pidof postfix | wc -l) -gt 0 ] && xbi_package restart "postfix"

	# Configuration for nginx
	[ $(pidof nginx | wc -l) -gt 0 ] && xbi_package restart "nginx" && echo_status info "Using nginx"

	# Configuration for apache2
	#xbi_cmd "ln -s /etc/mailman/apache.conf /etc/apache2/conf.d/mailman.conf"
	[ $(pidof apache2 | wc -l) -gt 0 ] && xbi_package restart "apache2" && echo_status info "Using apache2"

	xbi_package restart "mailman"
}



#-------------------------------------------------------------------------------
# TASK: Web-Statistics
#-------------------------------------------------------------------------------
label["de_task_statistic_queue_configure"]="Konfiguriere Awstats"

label["en_task_statistic_queue_configure"]="Configure awstats"

function task_statistic() {
	xbi_hook init

	# Install packages for web-statistics
	xbi_package install "vlogger webalizer awstats geoip-database libclass-dbi-mysql-perl"

	# Comment all lines in /etc/cron.d/awstats
	xbi_cmdQueue "sed -i '/^#/! s/^/#/g' /etc/cron.d/awstats"
	xbi_cmdQueueExec configure

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Monitoring
#
# TODO: Configure munin
# TODO: nginx-directives
#-------------------------------------------------------------------------------
label["de_task_monitoring_queue_configure"]="Konfiguriere Munin"

label["en_task_monitoring_queue_configure"]="Configure Munin"

function task_monitoring() {
	xbi_hook init

	# Install packages
	#xbi_package install munin munin-node munin-plugins-extra
	xbi_package install "munin munin-node"

	# Configure munin (test included)
	xbi_cmdQueue "$(xbi_confMod uncomment 0 /etc/munin/munin.conf 'dbdir')"
	xbi_cmdQueue "$(xbi_confMod uncomment 0 /etc/munin/munin.conf 'htmldir')"
	xbi_cmdQueue "$(xbi_confMod uncomment 0 /etc/munin/munin.conf 'logdir')"
	xbi_cmdQueue "$(xbi_confMod uncomment 0 /etc/munin/munin.conf 'rundir')"
	xbi_cmdQueue "$(xbi_confMod uncomment 0 /etc/munin/munin.conf 'tmpldir')"
	xbi_cmdQueue "sed -i \"s/localhost.localdomain/${hostname}/g\" /etc/munin/munin.conf"
	xbi_cmdQueue "sed -i \"s/address 127.0.0.1/address ${ipAddress}/g\" /etc/munin/munin.conf"
	xbi_cmdQueue "[ \$(sed -n -e \"/^\[${hostname}\]/p\" /etc/munin/munin.conf | wc -l) -ge 1 ]"
	xbi_cmdQueue "[ \$(sed -n -e \"/^[\t ]*address ${ipAddress}/p\" /etc/munin/munin.conf | wc -l) -ge 1 ]"
	xbi_cmdQueueExec configure

	cd /etc/munin/plugins
	ln -s /usr/share/munin/plugins/mysql_ mysql_
	ln -s /usr/share/munin/plugins/mysql_bytes mysql_bytes
	ln -s /usr/share/munin/plugins/mysql_innodb mysql_innodb
	ln -s /usr/share/munin/plugins/mysql_isam_space_ mysql_isam_space_
	ln -s /usr/share/munin/plugins/mysql_queries mysql_queries
	ln -s /usr/share/munin/plugins/mysql_slowqueries mysql_slowqueries
	ln -s /usr/share/munin/plugins/mysql_threads mysql_threads

	# Supress errors in mysql_innodb
	echo -e "[mysql_innodb]\nenv.warning 0\nenv.critical 0" > /etc/munin/plugin-conf.d/mysql_innodb

	# Restart munin
	xbi_package restart "munin-node"

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: phpMyAdmin
#-------------------------------------------------------------------------------
function task_phpmyadmin() {
	xbi_hook init

	# Preconfiguration for unattended installation
	debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean false"
	debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password ${password_mysql}"
	debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect "

	# Install package
	xbi_package install "phpmyadmin"

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Roundcube Webmail (currently not available in debian jessie)
#-------------------------------------------------------------------------------
function task_roundcube() {
	xbi_hook init

	# Install packages
	#xbi_package install "roundcube roundcube-plugins roundcube-plugins-extra"

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Squirrelmail Webmail
# TODO: Configuration of squirrelmail ....but do we really want/need squirrelmail?
#-------------------------------------------------------------------------------
function task_squirrelmail() {
	xbi_hook init

	# Package installation
	xbi_package install "squirrelmail"

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Jailkit
#-------------------------------------------------------------------------------
label["de_task_jailkit_queue_configure"]="jailkit"
label["de_task_jailkit_queue_download"]="Downloade und dekomprimiere Quellcode"
label["de_task_jailkit_queue_compile"]="Kompiliere aus Quellcode"
label["de_task_jailkit_queue_install"]="Installiere jailkit"

label["en_task_jailkit_queue_configure"]="jailkit"
label["en_task_jailkit_queue_download"]="Download an uncompress source"
label["en_task_jailkit_queue_compile"]="Compile from source"
label["en_task_jailkit_queue_install"]="Install jailkit"

function task_jailkit() {
	xbi_hook init

	# Skip if jailkit is already installed
	if [ $(xbi_isInstalled "jailkit") -gt 0 ]; then

		# Install tools for compiling
		xbi_package install "build-essential autoconf automake libtool flex bison debhelper binutils"

		cd ${path_source}
		if [ ! -d "jailkit-${version_jailkit}" ]; then
			if [ ! -f "jailkit-${version_jailkit}.tar.gz" ]; then
				xbi_cmdQueue "wget http://olivier.sessink.nl/jailkit/jailkit-${version_jailkit}.tar.gz -O jailkit-${version_jailkit}.tar.gz"
			fi
			xbi_cmdQueue "tar xfz jailkit-${version_jailkit}.tar.gz"
			xbi_cmdQueueExec download
		fi

		xbi_hook preCompile

		# Compile from source
		cd ${path_source}/jailkit-${version_jailkit}/ &>/dev/null
		xbi_cmdQueue "cd ${path_source}/jailkit-${version_jailkit}/ && ./debian/rules binary"
		xbi_cmdQueueExec compile

		xbi_hook preInstall

		# Install jailkit
		cd ${path_source}
		xbi_cmdQueue "[ $(find . -name jailkit_${version_jailkit}*\.deb | wc -l) -gt 0 ]"
		xbi_cmdQueue "dpkg -i $(find . -name jailkit_${version_jailkit}*\.deb)"
		xbi_cmdQueueExec install
	fi

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: fail2ban
#-------------------------------------------------------------------------------
function task_fail2ban() {
	xbi_hook init

	# Install packages
	xbi_package install "fail2ban"

	# Backup configuration file
	xbi_backup "${path_fail2ban}/jail.local" "~"

	echo "[DEFAULT]
maxretry = 3
destemail = root@localhost

[pure-ftpd]
enabled = true
port = ftp,ftp-data,ftps,ftps-data
filter = pure-ftpd
logpath = /var/log/auth.log
maxretry = 4

[dovecot]
enabled = true
port = smtp,ssmtp,imap2,imap3,imaps,pop3,pop3s
filter = dovecot
logpath = /var/log/mail.log
maxretry = 5

[sasl]
enabled = true
#port = smtp
port = smtp,ssmtp,imap2,imap3,imaps,pop3,pop3s
filter = sasl
logpath = /var/log/mail.warn

[ssh-ddos]
enabled = true
port = ssh
filter = sshd-ddos
logpath = /var/log/auth.log
maxretry = 6" > ${path_fail2ban}/jail.local

	# Restart fail2ban
	xbi_package restart "fail2ban"

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Installation of ISPConfig 3
# TODO: check variables for ssl-certificate if empty
#-------------------------------------------------------------------------------
label["de_task_ispconfig_phpmissing_fail"]="PHP ist nicht verfügbar"
label["de_task_ispconfig_mod_fail"]="Fehler beim modifizieren des ISPConfig-Installers"
label["de_task_ispconfig_install_fail"]="Installation konnte nicht durchgeführt werden"
label["de_task_ispconfig_summary_fail"]="Folgende Fehler traten bei der Installation auf:"
label["de_task_ispconfig_source_fail"]="Quelle nicht verfügbar"
label["de_task_ispconfig_queue_download"]="Downloade und dekomprimiere ISPConfig-Installer"
label["de_task_ispconfig_queue_iniMods"]="Vorkonfiguration von ISPConfig"
label["de_task_ispconfig_queue_install"]="Installiere ISPConfig"

label["en_task_ispconfig_phpmissing_fail"]="PHP is not available"
label["en_task_ispconfig_mod_fail"]="Failed to modifiy the ISPConfig-installer"
label["en_task_ispconfig_install_fail"]="Installation could not be executed"
label["en_task_ispconfig_summary_fail"]="The following errors occured:"
label["en_task_ispconfig_source_fail"]="Source not available"
label["en_task_ispconfig_queue_download"]="Download an uncompress ISPConfig-installer"
label["en_task_ispconfig_queue_iniMods"]="Preconfigure ISPConfig"
label["en_task_ispconfig_queue_install"]="Install ISPConfig"

function task_ispconfig() {
	xbi_hook init

	installFailedMsg=""
	local path_ispconfig_install="${path_source}/ispconfig3_install/install"

	# Check for running php
	[ $(which php | wc -l) -eq 0 ] && xbi_fail "$(xbi_label task_ispconfig_phpmissing_fail)"

	# Restart Web-Server
	if [ $(pidof apache2 | wc -l) -gt 0 ]; then
		defaultWebServer="apache2"
	else
		defaultWebServer="nginx"
	fi
	[ $(xbi_isInstalled ${defaultWebServer}) -eq 0 ] || xbi_package restart "${defaultWebServer}"

	# Change to source-dir
	cd ${path_source}
	# Download an uncompress ISPConfig-installer
	if [ ! -d "ispconfig3_install/install/" ]; then
		if [ ! -f "ISPConfig-3-stable.tar.gz" ]; then
			xbi_cmdQueue "wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz -O ISPConfig-3-stable.tar.gz"
		fi
		xbi_cmdQueue "tar xfz ISPConfig-3-stable.tar.gz"
		xbi_cmdQueueExec download
	fi

	# Proceed if installer is available
	[ -d "ispconfig3_install/install/" ] && cd ispconfig3_install/install/ || xbi_fail "$(xbi_label task_ispconfig_source_fail)"

	xbi_hook preinstall

	# Create backups if needed
	xbi_backup "tpl/system.ini.master" "~"
	xbi_backup "tpl/server.ini.master" "~"

	# Convert DOS to UNIX linebreaks to use sed for replacing parameter values later
	xbi_cmd "tr -d '\15\32' < ${path_ispconfig_install}/tpl/system.ini.master~ > ${path_ispconfig_install}/tpl/system.ini.master"
	xbi_cmd "tr -d '\15\32' < ${path_ispconfig_install}/tpl/server.ini.master~ > ${path_ispconfig_install}/tpl/server.ini.master"

	# Prepare autoinstall.ini for unattended installation of ispconfig3 (tested with 3.0.5.4p9)
	xbi_cmd "tr -d '\15\32' < ${path_ispconfig_install}/../docs/autoinstall_samples/autoinstall.ini.sample > ${path_ispconfig_install}/autoinstall.ini"

	### Preconfiguration for autoinstall.ini

	# Section [install]
	[ "${installerLanguage}" = "de" ] && xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/autoinstall.ini install language ${installerLanguage})"
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/autoinstall.ini install hostname ${hostname})"
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/autoinstall.ini install mysql_root_password ${password_mysql})"
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/autoinstall.ini install http_server ${defaultWebServer})"
	# Section [ssl_cert]
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/autoinstall.ini ssl_cert ssl_cert_country "${ssl_countryName}")"
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/autoinstall.ini ssl_cert ssl_cert_state "${ssl_stateOrProvinceName}")"
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/autoinstall.ini ssl_cert ssl_cert_locality "${ssl_localityName}")"
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/autoinstall.ini ssl_cert ssl_cert_organisation "${ssl_organizationName}")"
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/autoinstall.ini ssl_cert ssl_cert_organisation_unit "${ssl_organizationalUnitName}")"
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/autoinstall.ini ssl_cert ssl_cert_common_name "${ssl_commonName}")"

	### Preconfiguration for ISPConfig: Main/Server Config

	# Mailinglist Administrator's e-mail
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/tpl/system.ini.master mail admin_mail ${systemEmailAddress})"
	# Create Subdomains as web site
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/tpl/system.ini.master sites vhost_subdomains y)"
	# Tools/Language
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/tpl/system.ini.master tools language ${installerLanguage})"
	# Use the domain limits in client module to add new domains
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/tpl/system.ini.master domains use_domain_module y)"
	# Translated message for "HTML to create a new domain"
	[ "${installerLanguage}" = "de" ] && xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/tpl/system.ini.master domains new_domain_html 'Bitte wenden Sie sich an unseren Support, um eine neue Domain für Sie zu erstellen.')"
	# Session timeout (minutes)
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/tpl/system.ini.master misc session_timeout 15)"
	# Minimum password length
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/tpl/system.ini.master misc min_password_length 12)"
	# Minimum password strength
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/tpl/system.ini.master misc min_password_strength 4)"

	# SSL Settings: CA passphrase
	[[ ${tasks_install["ca"]} ]] && xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/tpl/server.ini.master web CA_pass ${password_ca})"
	# SSL Settings: CA Path
	[[ ${tasks_install["ca"]} ]] && xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/tpl/server.ini.master web CA_path ${path_ssl})"
	# DNSBL Realtime blackhole lists
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/tpl/server.ini.master web realtime_blackhole_list ${dnsbl})"
	# FastCGI configurations syntax
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_ispconfig_install}/tpl/server.ini.master fastcgi fastcgi_config_syntax 2)"
	# Set PHP-FPM FastCGI process-manager to "ondemand"
	xbi_cmdQueue "sed -i 's/^pm = dynamic/pm = ondemand/g' ${path_ispconfig_install}/tpl/apps_php_fpm_pool.conf.master"
	xbi_cmdQueue "sed -i 's/^pm = dynamic/pm = ondemand/g' ${path_ispconfig_install}/tpl/php_fpm_pool.conf.master"

	# Replace admin-password and language
	xbi_cmdQueue "sed -i \"s/'21232f297a57a5a743894a0e4a801fc3'/md5('${password_ispconfig}')/g\" ${path_ispconfig_install}/sql/ispconfig3.sql"
	[ "${installerLanguage}" != "en" ] && xbi_cmdQueue "sed -i \"s/'en'/'${installerLanguage}'/g\" ${path_ispconfig_install}/sql/ispconfig3.sql"

	# Execute command-queue
	xbi_cmdQueueExec iniMods

	# Reset Log
	[ -f /var/log/ispconfig_install.log ] && rm /var/log/ispconfig_install.log

	# Execute ispconfig-installer and set admin-password
	xbi_cmdQueue "php -q -e ${path_ispconfig_install}/install.php --autoinstall=${path_ispconfig_install}/autoinstall.ini"
	xbi_cmdQueueExec install

	# Check for failed ispconfig-installer tasks
	if [ ! -f /var/log/ispconfig_install.log ]; then
		echo ""
		installFailedMsg="$(xbi_label task_ispconfig_install_fail)"
	else
		if [ $(egrep -i "fail|error" /var/log/ispconfig_install.log | wc -l) -gt 0 ]; then
			ispconfigErrors="$(egrep -i 'fail|error' /var/log/ispconfig_install.log | sed -b -e 's/ \[ISPConfig\] - \/usr\/local\/src\/ispconfig3_install\/install\/lib\/installer_base.lib.php, Line [[:digit:]]*://g')"
			installFailedMsg="$(xbi_label task_ispconfig_summary_fail)\n${ispconfigErrors}"
		fi
	fi

	# Remove installer
	#rm -rf ${path_source}/ispconfig3_install

	# Output error-message
	if [ ${#installFailedMsg} -gt 0 ]; then
		xbi_fail "${installFailedMsg}"
	fi

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: create CA
#-------------------------------------------------------------------------------
# http://www.eclectica.ca/howto/ssl-cert-howto.php/
# https://help.ubuntu.com/community/OpenSSL
# check connection: openssl s_client -cipher 'ECDH:DH' -connect srv1.t48.at:8080

label["de_ca_generateKeyCa"]="Erzeuge Schlüssel für die CA"
label["de_ca_newCa"]="Erzeuge CA aus dem generierten Schlüssel"
label["de_ca_generateKeyIspc"]="Erzeuge einen Schlüssel für das ISPConfig-Zertifikat"
label["de_ca_removeProtection"]="Entferne Passwortschutz vom Schlüssel"
label["de_ca_createCsr"]="Erzeuge Zertifikats-Signierungsanfrage (CSR) für ISPConfig"
label["de_ca_signIspconfig"]="Signiere Zertifikat mit eigener CA"
label["de_ca_caAlreadyExistQuestion"]="CA Existiert bereits. Überschreiben [J/n]?"
label["de_ca_caAlreadyExist"]="CA existiert bereits"
label["de_task_ca_queue_replaceVarsCa"]="Ersetze Variablen im Block [CA_default] und [tsa_config1]"
label["de_task_ca_queue_replaceVarsPolicy"]="Ersetze Variablen im Block [policy_match]"
label["de_task_ca_queue_replaceVarsReq"]="Ersetze Variablen im Block [req]"
label["de_task_ca_queue_linkCertificates"]="Erstelle Symlinks zu den Zertifikaten"

label["en_ca_generateKeyCa"]="Generate encrypted private key for the CA"
label["en_ca_newCa"]="Create CA from generated key"
label["en_ca_generateKeyIspc"]="Generate key for the ISPConfig-certificate"
label["en_ca_removeProtection"]="Remove protection from key"
label["en_ca_createCsr"]="Create certificate-signing-request (CSR) for ISPConfig"
label["en_ca_signIspconfig"]="Sign CSR with own CA"
label["de_ca_caAlreadyExist"]="CA already exist"
label["en_task_ca_queue_replaceVarsCa"]="Replace variables in block [CA_default] and [tsa_config1]"
label["en_task_ca_queue_replaceVarsPolicy"]="Replace variables in block [policy_match]"
label["en_task_ca_queue_replaceVarsReq"]="Replace variables in block [req]"
label["en_task_ca_queue_linkCertificates"]="Create symlinks to the certificates"

function task_ca() {
	xbi_hook init

	# Certificate-authority
	caConf=${path_ssl}/openssl.cnf
	caKey=${path_ca}/private/cakey.pem
	caReq=${path_ca}/careq.pem
	caCrt=${path_ca}/cacert.pem

	# ISPConfig-certificate
	ispconfigKey=${path_ispconfig_ssl}/ispserver.key
	ispconfigCsr=${path_ispconfig_ssl}/ispserver.csr
	ispconfigCrt=${path_ispconfig_ssl}/ispserver.crt
	ispconfigPem=${path_ispconfig_ssl}/ispserver.pem

	# ftp-certificate
	ftpPem=${path_pureftp_ssl}/pure-ftpd.pem

	# Postfix/dovecot-certificate
	postfixKey=${path_postfix}/smtpd.key
	postfixCrt=${path_postfix}/smtpd.cert

	local password_cert=$(date +%s | sha256sum | base64 | head -c 32)

	# TODO: automate
	if [ -d ${path_ca} ] ; then
		echo ""
		read -p "CA Existiert bereits in ${path_ca}. Überschreiben [J/n]? " action
		if [ $action ] && [ $action = "n" -o $action = "N" ]; then
			xbi_fail "$(xbi_label ca_caAlreadyExist): ${path_ca}"
		else
			rm ${path_ca} -rf
		fi
	fi

	# Install openssl
	xbi_package install "openssl"

	# Backup configuration file
	xbi_backup "${caConf}" ".dpkg"

	# Replace variables in block [CA_default] and [tsa_config1]
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${caConf} CA_default dir ${path_ca})"
	xbi_cmdQueue "$(xbi_iniMod uncomment 0 ${caConf} CA_default unique_subject)"	# Allow non-unique subjects to avoid problems in ispconfig
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${caConf} tsa_config1 dir ${path_ca})"
	xbi_cmdQueueExec replaceVarsCa

	# Replace variables in block [policy_match]
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${caConf} policy_match countryName optional)"
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${caConf} policy_match stateOrProvinceName optional)"
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${caConf} policy_match organizationName optional)"
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${caConf} policy_match localityName optional)"
	xbi_cmdQueueExec replaceVarsPolicy

	# Replace variables in block [req]
	xbi_cmdQueue "$(xbi_iniMod setValue 0 ${caConf} req default_bits ${ssl_bitLength})"
	xbi_cmdQueueExec replaceVarsReq

	# Create directories for the new CA
	cd ${path_ssl}
	mkdir -p ${path_ca} ${path_ca}/newcerts ${path_ca}/private ${path_ca}/certs ${path_ca}/newcerts
	echo '01' > ${path_ca}/serial
	touch ${path_ca}/index.txt
	#mkdir -p ispconfigCA ispconfigCA/newcerts ispconfigCA/private ispconfigCA/certs ispconfigCA/newcerts && cd ispconfigCA/; echo '01' >ispconfigCA/serial; touch ispconfigCA/index.txt; cd ..

	# Subject for certificates (used by ispconfig/postfix/dovecot/pure-ftpd)
	local sslSubj="/C=${ssl_countryName}/ST=${ssl_stateOrProvinceName}/L=${ssl_localityName}/O=${ssl_organizationName}/OU=${ssl_organizationalUnitName}/CN=${ssl_commonName}/emailAddress=${ssl_email}"

	# Subject for CA
	#local caSubj="/C=${ca_countryName}/O=${ca_organizationName}/CN=${ca_commonName}"
	local caSubj="/C=${ca_countryName}"
	[[ ${ca_stateOrProvinceName} ]] && caSubj="${caSubj}/ST=${ca_stateOrProvinceName}"
	[[ ${ca_localityName} ]] && caSubj="${caSubj}/L=${ca_localityName}"
	[[ ${ca_organizationName} ]] && caSubj="${caSubj}/O=${ca_organizationName}"
	[[ ${ca_organizationalUnitName} ]] && caSubj="${caSubj}/OU=${ca_organizationalUnitName}"
	[[ ${ca_commonName} ]] && caSubj="${caSubj}/CN=${ca_commonName}"
	[[ ${ca_email} ]] && caSubj="${caSubj}/emailAddress=${ca_email}"

	# Generate encrypted private key for the CA:
	# openssl req \
	#	-new \
	#	-config ${caConf} \
	#	-subj "/C=${ca_countryName}/O=${ca_organizationName}/CN=${ca_organizationName}" \
	#	-passin pass:${password_ca} \
	#	-passout pass:${password_ca} \
	#	-newkey rsa:4096 \
	#	-keyout ${caKey} \
	#	-out ${caReq}
	#xbi_cmd "openssl req -new -config ${caConf} -subj \"/C=${ca_countryName}/O=${ca_organizationName}/CN=${ca_commonName}\" -passin pass:${password_ca} -passout pass:${password_ca} -newkey rsa:4096 -keyout ${caKey} -out ${caReq}" \
	xbi_cmd "openssl req -new -config ${caConf} -subj \"${caSubj}\" -passin pass:${password_ca} -passout pass:${password_ca} -newkey rsa:${ssl_bitLength} -keyout ${caKey} -out ${caReq}" \
		"$(xbi_label ca_generateKeyCa)"

	# Create CA from generated key
	# openssl ca \
	#	-config ${caConf} \
	#	-passin pass:${password_ca} \
	#	-create_serial \
	#	-out ${caCrt} \
	#	-days ${caDays} \
	#	-batch \
	#	-noemailDN \
	#	-keyfile ${caKey} -selfsign \
	#	-extensions v3_ca \
	#	-infiles ${caReq}
	xbi_cmd "openssl ca -config ${caConf} -passin pass:${password_ca} -create_serial -out ${caCrt} -days ${ssl_days} -batch -noemailDN -keyfile ${caKey} -selfsign -extensions v3_ca -infiles ${caReq}" \
		"$(xbi_label ca_newCa)"

	# Generate a key for the ispconfig-certificate:
	# openssl genrsa \
	#	-aes256 \
	#	-passout pass:$password_cert \
	#	-out ${ispconfigKey}.secure \
	#	4096
	xbi_cmd "openssl genrsa -aes256 -passout pass:${password_cert} -out ${ispconfigKey}.secure ${ssl_bitLength}" \
		"$(xbi_label ca_generateKeyIspc)"
	# Protect the key-file:
	chmod 400 ${ispconfigKey}.secure

	# Remove password-protection from the key:
	# openssl rsa \
	#	-passin pass:$password_cert \
	#	-in ${ispconfigKey}.secure \
	#	-out ${ispconfigKey}
	xbi_cmd "openssl rsa -passin pass:${password_cert} -in ${ispconfigKey}.secure -out ${ispconfigKey}" \
		"$(xbi_label ca_removeProtection)"
	# Protect the key-file:
	chmod 400 ${ispconfigKey}

	# Create certificate-signing-request (CSR) for ispconfig
	# openssl req \
	#	-new \
	#	-passin pass:$password_cert \
	#	-key ${ispconfigKey}.secure \
	#	-out ${ispconfigCsr} \
	#	-nodes \
	#	-subj \"${sslSubj}\"
	xbi_cmd "openssl req -new -passin pass:${password_cert} -key ${ispconfigKey}.secure -out ${ispconfigCsr} -nodes -subj \"${sslSubj}\"" \
		"$(xbi_label ca_createCsr)"

	# Sign the CSR with own CA:
	# openssl ca \
	#	-config ${caConf} \
	#	-passin pass:${password_ca} \
	#	-in ${ispconfigCsr} \
	#	-notext \
	#	-noemailDN \
	#	-out ${ispconfigCrt} \
	#	-days ${caDays} \
	#	-batch
	xbi_cmd "openssl ca -config ${caConf} -passin pass:${password_ca} -in ${ispconfigCsr} -notext -noemailDN -out ${ispconfigCrt} -days ${ssl_days} -batch" \
		"$(xbi_label ca_signIspconfig)"

	# (Alternative) Sign Certificate without CA
	# openssl req \
	#	-noemailDN \
	#	-passin pass:${password_cert} \
	#	-key ispserver.key \
	#	-in ispserver.csr \
	#	-out ispserver.crt \
	#	-days 2555

	# Copy unprotected key and certificate into one PEM-file for pure-ftpd and postfix/dovecot
	xbi_cmdQueue "{ cat ${ispconfigKey} ${ispconfigCrt} >${ispconfigPem}; }"
	xbi_cmdQueue "chmod 0400 ${ispconfigPem}"
	xbi_cmdQueue "chown ispconfig:ispconfig ${ispconfigPem}"
	# Link the pem-file to pure-ftpd
	xbi_cmdQueue "[ -h ${ftpPem} ] || [ -f ${ftpPem} ] && mv ${ftpPem} ${ftpPem}~"
	xbi_cmdQueue "ln -s ${ispconfigPem} ${ftpPem}"
	# Link the key-file and the certificate-file to postfix/dovecot
	xbi_cmdQueue "[ -h ${postfixCrt} ] || [ -f ${postfixCrt} ] && mv ${postfixCrt} ${postfixCrt}~"
	xbi_cmdQueue "ln -s ${ispconfigCrt} ${postfixCrt}"
	xbi_cmdQueue "[ -h ${postfixKey} ] || [ -f ${postfixKey} ] && mv ${postfixKey} ${postfixKey}~"
	xbi_cmdQueue "ln -s ${ispconfigKey} ${postfixKey}"
	xbi_cmdQueueExec linkCertificates

	# Restart Web-Server
	[ $(pidof nginx | wc -l) -gt 0 ] && xbi_package restart "nginx"
	[ $(pidof apache2 | wc -l) -gt 0 ] && xbi_package restart "apache2"

	# Restart Mail-Server
	[ $(pidof postfix | wc -l) -gt 0 ] && xbi_package restart "postfix"
	[ $(pidof dovecot | wc -l) -gt 0 ] && xbi_package restart "dovecot"

	# Restart FTP-Server
	[ $(pidof pure-ftpd-mysql | wc -l) -gt 0 ] && xbi_package restart "pure-ftpd-mysql"

	xbi_hook post
}

# Test-Task
function task_restoreCertificate() {
	xbi_hook init

	rm ispserver.*
	openssl genrsa -des3 -passout pass:password -out ispserver.key 4096
	openssl req -new -subj "/C=AT/ST=Vienna/L=Vienna/O=T48/OU=restoreCertificate/CN=srv1.t48.at/emailAddress=webmaster@t48.at" -passin pass:password -passout pass:password -key ispserver.key -out ispserver.csr
	openssl req -x509 -passin pass:password -passout pass:password -key ispserver.key -in ispserver.csr -out ispserver.crt -days 3650
	openssl rsa -passin pass:password -in ispserver.key -out ispserver.key.insecure
	mv ispserver.key ispserver.key.secure
	mv ispserver.key.insecure ispserver.key
	cat ispserver.key ispserver.crt > ispserver.pem
	chown ispconfig:ispconfig ispserver.*
	#service nginx restart
	xbi_package restart "nginx"

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Securing the Server
#-------------------------------------------------------------------------------
label["de_task_secure_queue_postfixDhparameter"]="Erstelle DH-Parameterdateien für Postfix (Das kann eine Weile dauern)"
label["de_task_secure_queue_postfix"]="Konfiguriere Postfix"
label["de_task_secure_queue_dovecot"]="Konfiguriere Dovecot"
label["de_task_secure_queue_nginxDhparameter"]="Erstelle DH-Parameterdatei für nginx (Das kann eine Weile dauern)"
label["de_task_secure_queue_nginx"]="Konfiguriere Nginx"

label["en_task_secure_queue_postfixDhparameter"]="Create DH-parameter files for Postfix (This is going to take a long time)"
label["en_task_secure_queue_postfix"]="Configure Postfix"
label["en_task_secure_queue_dovecot"]="Configure Dovecot"
label["en_task_secure_queue_nginxDhparameter"]="Create DH-parameter file for nginx (This is going to take a long time)"
label["en_task_secure_queue_nginx"]="Configure Nginx"

function task_secure() {
	xbi_hook init

	# Securing FTP-Server
	# TODO: Check if certificate is available
	echo 2 > /etc/pure-ftpd/conf/TLS
	xbi_package restart "pure-ftpd-mysql"

	# TODO: check if postfix accepts encrypted connections
	if [ $(xbi_isInstalled "postfix") -eq 0 ]; then

		### Postfix

		# Backup configuration files modified by ispconfig
		if [ -d ${path_ispconfig} ]; then
			xbi_backup "${path_postfix}/master.cf" ".ispconfig"
			xbi_backup "${path_postfix}/main.cf" ".ispconfig"
			xbi_backup "${path_dovecot}/dovecot.conf" ".ispconfig"
		fi

		# http://sys4.de/de/blog/2013/08/14/postfix-tls-forward-secrecy/
		# http://www.heise.de/security/artikel/Forward-Secrecy-testen-und-einrichten-1932806.html
		# https://www.incertum.net/archives/72-Forward-Secrecy-mit-Debianwheezy-postfix,-dovecot,-nginx.html
		[ -f /etc/postfix/dh_512.pem ] && rm /etc/postfix/dh_512.pem
		[ -f /etc/postfix/dh_2048.pem ] && rm /etc/postfix/dh_2048.pem
		xbi_cmdQueue "openssl dhparam -out ${path_postfix}/dh_512.pem 512"
		xbi_cmdQueue "openssl dhparam -out ${path_postfix}/dh_2048.pem 2048"
		xbi_cmdQueueExec postfixDhparameter

		xbi_cmdQueue '$(postconf "smtpd_banner = \$myhostname ESMTP \$mail_name")'
		# Helo restrictions
		xbi_cmdQueue "postconf 'smtpd_helo_required = yes'"
		xbi_cmdQueue "postconf 'smtpd_helo_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_non_fqdn_helo_hostname, reject_invalid_helo_hostname'"
		# Optional access restrictions that the Postfix SMTP server applies in the context of the SMTP DATA command
		xbi_cmdQueue "postconf 'smtpd_data_restrictions = reject_unauth_pipelining'"
		# When TLS encryption is optional in the Postfix SMTP server, do not announce or accept SASL authentication over unencrypted connections (Postfix 2.2 and later):
		# This is tricky: if enabled, there are no auth-mechs in nontls-connections available, but is neccessary for PLAIN and LOGIN!!!!
		xbi_cmdQueue "postconf 'smtpd_tls_auth_only = yes'"
		# This stops some techniques used to harvest email addresses
		xbi_cmdQueue "postconf 'disable_vrfy_command = yes'"
		# This stops mail from poorly written software
		xbi_cmdQueue "postconf 'strict_rfc821_envelopes = yes'"
		# Include information about the protocol and used cipher in email headers
		xbi_cmdQueue "postconf 'smtpd_tls_received_header = yes'"
		# Request that the Postfix SMTP server rejects mail from unknown sender addresses, even when no explicit 'reject_unlisted_sender' access restriction is specified. This can slow down an explosion of forged mail from worms or viruses.
		xbi_cmdQueue "postconf 'smtpd_reject_unlisted_sender = yes'"
		# Enable additional Postfix SMTP server logging of TLS activity (debug only!)
		#xbi_cmdQueue "postconf 'smtpd_tls_loglevel = 2')"
		# Log the hostname of a remote SMTP server that offers STARTTLS, when TLS is not already enabled for that server (Postfix 2.2 and later):
		xbi_cmdQueue "postconf 'smtp_tls_note_starttls_offer = yes'"
		# The numerical Postfix SMTP server response code when a recipient address is local, and $local_recipient_maps specifies a list of lookup tables that does not match the recipient:
		xbi_cmdQueue "postconf 'unknown_local_recipient_reject_code = 450'"
		# The numerical Postfix SMTP server response code when a remote SMTP client request is rejected by the 'reject' restriction:
		xbi_cmdQueue "postconf 'reject_code = 550'"

		# Clients restrictions
		if [[ ! $(postconf -h smtpd_client_restrictions | grep 'permit_mynetworks, permit_sasl_authenticated, reject_unknown_client_hostname') ]]; then
			xbi_cmdQueue "postconf 'smtpd_client_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unknown_client_hostname, $(postconf -h smtpd_client_restrictions)'"
		fi
		# Reject the request when Postfix is not the final destination for the recipient domain, and the RCPT TO domain has 1) no DNS MX and no DNS address record or 2) a malformed MX record such as a record with a zero-length MX hostname
		if [[ ! $(postconf -h smtpd_recipient_restrictions | grep 'reject_unknown_recipient_domain') ]]; then
			xbi_cmdQueue "postconf '$(postconf smtpd_recipient_restrictions), reject_unknown_recipient_domain'"
		fi

		xbi_cmdQueue "postconf 'smtpd_tls_dh1024_param_file = ${path_postfix}/dh_2048.pem'"
		xbi_cmdQueue "postconf 'smtpd_tls_dh512_param_file = ${path_postfix}/dh_512.pem'"
		xbi_cmdQueue "postconf 'tls_preempt_cipherlist = yes'"
		xbi_cmdQueue "postconf 'smtpd_tls_protocols = !SSLv2'"
		xbi_cmdQueue "postconf 'smtpd_tls_security_level = encrypt'"
		xbi_cmdQueue "postconf 'smtpd_tls_mandatory_ciphers = high'"
		xbi_cmdQueue "postconf 'smtpd_tls_mandatory_exclude_ciphers = aNULL, MD5'"
		#smtpd_tls_mandatory_ciphers = ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4
		xbi_cmdQueue "postconf 'smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3'"
		#smtpd_tls_mandatory_protocols = SSLv3, TLSv1

		xbi_cmdQueueExec postfix

		# TEST: openssl s_client -starttls imap -connect srv3.sonority.at:143
		# TEST: openssl s_client -starttls smtp -connect srv3.sonority.at:25
		# TEST: openssl s_client -cipher 'ECDH:DH' -connect srv3.sonority.at:8080
	fi
	if [ $(xbi_isInstalled "dovecot-core") -eq 0 ]; then
		### Dovecot
		xbi_cmdQueue "$(xbi_iniMod uncomment 0 ${path_dovecot}/dovecot.conf disable_plaintext_auth)"
		xbi_cmdQueue "$(xbi_iniMod setValue 0 ${path_dovecot}/dovecot.conf disable_plaintext_auth yes)"
		# Log used ciphers
		xbi_cmdQueue "$(xbi_iniMod uncomment 0 ${path_dovecot}/conf.d/10-logging.conf login_log_format_elements)"
		xbi_cmdQueue "$(xbi_iniMod appendValue 0 ${path_dovecot}/conf.d/10-logging.conf login_log_format_elements '%k' ' ')"

		xbi_cmdQueueExec dovecot

		#zegrep "TLS connection established from.*with cipher" /var/log/mail.log | awk '{printf("%s %s %s %s\n", $12, $13, $14, $15)}' | sort | uniq -c | sort -n

		# TODO: ssl_cipher_list in /etc/dovecot/conf.d/10-ssl.conf
		# ssl_cipher_list = ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4
		# TODO: ???
		#sed -i 's/#*\(disable_plaintext_auth *= *\).*/\1yes/' ${path_dovecot}/dovecot.conf

		# TODO: Link CLASS3-root-certificate
		#echo -e "\n\nssl_ca = </etc/ssl/certs/ca-certificates.crt" >> ${path_dovecot}/dovecot.conf

	fi

	# Securing nginx (PFS)
	# http://www.howtoforge.com/ssl-perfect-forward-secrecy-in-nginx-webserver
	# See: https://community.qualys.com/blogs/securitylabs/2013/08/05/configuring-apache-nginx-and-openssl-for-forward-secrecy
	# This MUST be inserted AFTER the lines that includes .../sites-enabled/*, otherwise SSLv3 support may be re-enabled accidentally.
	if [ $(xbi_isInstalled "nginx") -eq 0 ]; then

		# Add DH-params
		[ -f /etc/nginx/dh4096.pem ] && rm /etc/nginx/dh4096.pem
		xbi_cmdQueue "openssl dhparam -out /etc/nginx/dh_4096.pem 4096"
		xbi_cmdQueueExec nginxDhparameter

		touch /etc/nginx/perfect-forward-secrecy.conf

		# Add session cache
		[[ ! $(grep "ssl_session_cache" /etc/nginx/perfect-forward-secrecy.conf) ]] && xbi_cmdQueue "echo -e '\nssl_session_cache shared:SSL:10m;\nssl_session_timeout 10m;' >>/etc/nginx/perfect-forward-secrecy.conf"

		# Add ciphers and encryption
		#[[ ! $(grep "ssl_protocols" /etc/nginx/perfect-forward-secrecy.conf) ]] && xbi_cmdQueue "echo -e '\nssl_protocols TLSv1 TLSv1.1 TLSv1.2;' >>/etc/nginx/perfect-forward-secrecy.conf"
		#[[ ! $(grep "ssl_prefer_server_ciphers" /etc/nginx/perfect-forward-secrecy.conf) ]] && xbi_cmdQueue "echo -e '\nssl_prefer_server_ciphers on;' >>/etc/nginx/perfect-forward-secrecy.conf"
		[[ ! $(grep "ssl_ciphers" /etc/nginx/perfect-forward-secrecy.conf) ]] && xbi_cmdQueue "echo -e '\nssl_ciphers \"EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS !MEDIUM\";' >>/etc/nginx/perfect-forward-secrecy.conf"

		[[ ! $(grep "dh_4096.pem" /etc/nginx/perfect-forward-secrecy.conf) ]] && xbi_cmdQueue "echo -e '\nssl_dhparam dh_4096.pem;' >>/etc/nginx/perfect-forward-secrecy.conf"

		#
		[[ ! $(grep "Strict-Transport-Security" /etc/nginx/perfect-forward-secrecy.conf) ]] && xbi_cmdQueue "echo -e '\n#add_header Strict-Transport-Security \"max-age=31536000; includeSubDomains\";\n#add_header X-Frame-Options DENY;' >>/etc/nginx/perfect-forward-secrecy.conf"
		# See: http://forum.nginx.org/read.php?2,152294,152401#msg-152401
		[[ ! $(grep "perfect-forward-secrecy.conf" /etc/nginx/nginx.conf) ]] && xbi_cmdQueue "sed -i -e '/^http {$/,/^}$/ { s/}/\n\tinclude perfect-forward-secrecy.conf;\n}/ }' /etc/nginx/nginx.conf"

		xbi_cmdQueueExec nginx

		xbi_package restart "nginx"
	fi

	# Secure apps-vhost-template with SSL-certificate
	if [ -d ${path_ispconfig} ]; then
		xbi_backup "${path_ispconfig}/server/conf/nginx_apps.vhost.master"
		xbi_backup "${path_ispconfig}/server/conf/apache_ispconfig.conf.master"

		# Add ispconfig-certificates to apps-vhost
		if [[ ! $(grep "ssl_certificate" ${path_ispconfig}/server/conf/nginx_apps.vhost.master) ]]; then
			sed -i "s/\(listen.*\)/\1\n\n        ssl on;\n        ssl_certificate ${path_ispconfig//\//\\/}\/interface\/ssl\/ispserver\.crt;\n        ssl_certificate_key ${path_ispconfig//\//\\/}\/interface\/ssl\/ispserver\.key;/g" ${path_ispconfig}/server/conf/nginx_apps.vhost.master
		fi
		if [[ ! $(grep "ssl_certificate" /etc/nginx/sites-available/apps.vhost) ]]; then
			sed -i "s/\(listen.*\)/\1\n\n        ssl on;\n        ssl_certificate ${path_ispconfig//\//\\/}\/interface\/ssl\/ispserver\.crt;\n        ssl_certificate_key ${path_ispconfig//\//\\/}\/interface\/ssl\/ispserver\.key;/g" /etc/nginx/sites-available/apps.vhost
		fi
		# TODO: Add SSLCertificateFile to apache-template

		# Allow only secure connections toe the ispconfig-apps-vhosts
		sed -i "s/\$https;/on;/g" ${path_ispconfig}/server/conf/nginx_apps.vhost.master
		sed -i "s/\$https;/on;/g"  /etc/nginx/sites-available/apps.vhost

		# Replace "squirrelmail" with "roundcube"
		if [ $(xbi_isInstalled "roundcube") -gt 0 ]; then
			sed -i "s/squirrelmail/roundcube/g" ${path_ispconfig}/server/conf/nginx_apps.vhost.master
			sed -i "s/squirrelmail/roundcube/g" /etc/nginx/sites-available/apps.vhost
			sed -i "s/squirrelmail/roundcube/g" ${path_ispconfig}/server/conf/apache_ispconfig.conf.master
			# TODO: replacement for apache-directive
		fi
	fi

	# Restart Web-Server
	[ $(pidof nginx | wc -l) -gt 0 ] && xbi_package restart "nginx"
	[ $(pidof apache2 | wc -l) -gt 0 ] && xbi_package restart "apache2"

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Mail-Server: delayed delivery with Postgrey
# TODO: check if postgrey is up and running
#-------------------------------------------------------------------------------
label["de_task_postgrey_queue_configure"]="Aktiviere Postgrey in Postfix"

label["en_task_postgrey_queue_configure"]="Enable Postgrey in Postfix"

function task_postgrey() {
	xbi_hook init

	# Install Packages
	xbi_package install "postgrey"

	if [[ ! $(postconf -h smtpd_recipient_restrictions | grep "check_policy_service inet:127.0.0.1:10023") ]]; then
		xbi_cmdQueue "postconf '$(postconf smtpd_recipient_restrictions), check_policy_service inet:127.0.0.1:10023'"
		xbi_cmdQueueExec configure
	fi

	xbi_hook post
}



#-------------------------------------------------------------------------------
# TASK: Mail-Server: Sender Policy Framework
# TODO: Check if SPF is running
#-------------------------------------------------------------------------------
label["de_task_spf_queue_configure"]="Aktiviere SPF in Postfix"

label["en_task_spf_queue_configure"]="Enable SPF in Postfix"

function task_spf() {
	xbi_hook init

	# Package installation
	xbi_package install "postfix-policyd-spf-python"

	xbi_backup "${path_postfix}/master.cf" ".dpkg"

	# Enable SPF in postfix
	if [ $(grep "^policy-spf" ${path_postfix}/master.cf | wc -l) -eq 0 ]; then
		xbi_cmdQueue "echo -e \"# SPF Check For Postfix\npolicy-spf  unix  -       n       n       -       -       spawn\n  user=nobody argv=/usr/bin/policyd-spf\n\" >>${path_postfix}/master.cf"
	fi
	xbi_cmdQueue "postconf 'policy-spf_time_limit = 3600s'"
	if [[ ! $(postconf -h smtpd_recipient_restrictions | grep "check_policy_service unix::private/policy-spf") ]]; then
		xbi_cmdQueue "postconf '$(postconf smtpd_recipient_restrictions), check_policy_service unix::private/policy-spf'"
	fi
	xbi_cmdQueueExec configure

	# Restart postfix
	xbi_package restart "postfix"

	xbi_hook post
}







################################################################################
# VIEWS & DIALOGS
################################################################################

#-------------------------------------------------------------------------------
# Prepare user-variables for ispckickstarter
#-------------------------------------------------------------------------------
function ispckickstarter_dialog_userVariables() {

	### Show dialogs

	# Userinput: Apt-source
	# Source-URL for the package-manager
	if [[ ${tasks_install["apt"]} ]]; then
		if [[ ! ${aptSource} ]]; then
			aptSource="${default_aptSource}"
			ispckickstarter_dialog_show "aptSource"
		fi
	fi

	# Userinput: Hostname
	# Hostname to use for this installation
	if
		[[ ${tasks_install["hostname"]} ]] ||
		[[ ${tasks_install["mail"]} ]] ||
		[[ ${tasks_install["monitoring"]} ]] ||
		[[ ${tasks_install["ispconfig"]} ]] ||
		[[ ${tasks_install["ca"]} ]] ||
		[[ ${tasks_install["secure"]} ]];
	then
		if [[ ! ${hostname} ]]; then
			hostname="${default_hostname}"
			ispckickstarter_dialog_show "hostname"
		fi
	fi

	# Userinput: IP-address
	# Set IP-address of this server
	if
		[[ ${tasks_install["network"]} ]] ||
		[[ ${tasks_install["hostname"]} ]] ||
		[[ ${tasks_install["monitoring"]} ]];
	then
		if [[ ! ${ipAddress} ]]; then
			ipAddress="${default_ipAddress}"
			ispckickstarter_dialog_show "ipAddress"
		fi
	fi

	# Userinput: time-server
	# Default timeserver, i.e.: "at.pool.ntp.org" (http://www.pool.ntp.org/zone/europe)
	if [[ ${tasks_install["ntp"]} ]]; then
		if [[ ! ${timeServer} ]]; then
			timeServer="${default_timeServer}"
			ispckickstarter_dialog_show "timeServer"
		fi
	fi

	# Userinput: webserver
	# Default web-server if "nginx" and "apache2" are installed
	if [[ ${tasks_install["ispconfig"]} ]]; then
		if
			( [[ ${tasks_install["nginx"]} ]] && [[ ${tasks_install["apache2"]} ]] ) ||
			( [[ ${tasks_install["nginx"]} ]] && [[ $(xbi_isInstalled "apache2") -eq 0 ]] ) ||
			( [[ ${tasks_install["apache2"]} ]] && [[ $(xbi_isInstalled "nginx") -eq 0 ]] ) ||
			( [[ $(xbi_isInstalled "nginx") -eq 0 ]] && [[ $(xbi_isInstalled "apache2") -eq 0 ]] );
		then
			if [[ ! ${defaultWebServer} ]]; then
				defaultWebServer="${default_defaultWebServer}"
				# Override default web-server if it was not selected and is not already installed
				if [[ ${tasks_install["apache2"]} ]] && [[ ! ${tasks_install["nginx"]} ]] && [[ $(xbi_isInstalled "nginx") -eq 1 ]]; then
					defaultWebServer="apache2"
				elif [[ ${tasks_install["nginx"]} ]] && [[ ! ${tasks_install["apache2"]} ]] && [[ $(xbi_isInstalled "apache2") -eq 1 ]]; then
					defaultWebServer="nginx"
				fi
				ispckickstarter_dialog_show "defaultWebServer"
			fi
		fi
	fi

	# Userinput: Current timezone
	# Current timezone (http://www.php.net/manual/de/timezones.php)
	if
		[[ ${tasks_install["nginx"]} ]] ||
		[[ ${tasks_install["apache2"]} ]];
	then
		if [[ ! ${dateTimeZone} ]]; then
			dateTimeZone="${default_dateTimeZone}"
			ispckickstarter_dialog_show "dateTimeZone"
		fi
	fi

	# Userinput: System-E-Mail
	if
		[[ ${tasks_install["ftp"]} ]] ||
		[[ ${tasks_install["mailinglist"]} ]] ||
		[[ ${tasks_install["ispconfig"]} ]] ||
		[[ ${tasks_install["ca"]} ]];
	then
		if [[ ! ${systemEmailAddress} ]]; then
			systemEmailAddress="${default_systemEmailAddress}"
			ispckickstarter_dialog_show "systemEmailAddress"
		fi
	fi

	# Userinput: CA Data
	if [[ ${tasks_install["ca"]} ]]; then
		# Userinput: CA->Country
		if [[ ! ${ca_countryName} ]]; then
			ca_countryName="${default_ca_countryName}"
			ispckickstarter_dialog_show "ca_countryName"
		fi
		# Userinput: CA->Common name
		if [[ ! ${ca_commonName} ]]; then
			ca_commonName="${default_ca_commonName}"
			ispckickstarter_dialog_show "ca_commonName"
		fi
		# Userinput: CA->Organization
		if [[ ! ${ca_organizationName} ]]; then
			ca_organizationName="${default_ca_organizationName}"
			ispckickstarter_dialog_show "ca_organizationName"
		fi
	fi

	# Userinput: SSL Data
	if
		[[ ${tasks_install["ispconfig"]} ]] ||
		[[ ${tasks_install["ca"]} ]] ||
		[[ ${tasks_install["secure"]} ]];
	then
		# Userinput: SSL->Country
		if [[ ! ${ssl_countryName} ]]; then
			ssl_countryName="${default_ssl_countryName}"
			ispckickstarter_dialog_show "ssl_countryName"
		fi
		# Userinput: SSL->State
		if [[ ! ${ssl_stateOrProvinceName} ]]; then
			ssl_stateOrProvinceName="${default_ssl_stateOrProvinceName}"
			ispckickstarter_dialog_show "ssl_stateOrProvinceName"
		fi
		# Userinput: SSL->City
		if [[ ! ${ssl_localityName} ]]; then
			ssl_localityName="${default_ssl_localityName}"
			ispckickstarter_dialog_show "ssl_localityName"
		fi
		# Userinput: SSL->Organization
		if [[ ! ${ssl_organizationName} ]]; then
			ssl_organizationName="${default_ssl_organizationName}"
			ispckickstarter_dialog_show "ssl_organizationName"
		fi
		# Userinput: SSL->Organizational unit
		if [[ ! ${ssl_organizationalUnitName} ]]; then
			ssl_organizationalUnitName="${default_ssl_organizationalUnitName}"
			ispckickstarter_dialog_show "ssl_organizationalUnitName"
		fi
		# Userinput: SSL->common name
		if [[ ! ${ssl_commonName} ]]; then
			ssl_commonName="${default_ssl_commonName}"
			ispckickstarter_dialog_show "ssl_commonName"
		fi
		# Userinput: SSL->email
		if [[ ! ${ssl_email} ]]; then
			ssl_email="${default_ssl_email}"
			ispckickstarter_dialog_show "ssl_email"
		fi
	fi

	# Userinput: MySQL-root-password (autogenerate if not set)
	if
		[ $(xbi_isInstalled "mysql-server") -eq 1 ];
	then
		if
			[[ ${tasks_install["mysql"]} ]] ||
			[[ ${tasks_install["ispconfig"]} ]] ||
			[[ ${tasks_install["phpmyadmin"]} ]] ||
			[[ ${tasks_install["roundcube"]} ]];
		then
			xbi_setPassword mysql
		fi
	fi

	# Userinput: ISPConfig admin-password (autogenerate if not set)
	[[ ${tasks_install["ispconfig"]} ]] && xbi_setPassword ispconfig

	# Userinput: Mailinglist admin-password (autogenerate if not set)
	[[ ${tasks_install["mailinglist"]} ]] && xbi_setPassword mailinglist

	# Userinput: Roundcube admin-password (autogenerate if not set)
	[[ ${tasks_install["roundcube"]} ]] && xbi_setPassword roundcube

	# Userinput: Password for certificate-authority (autogenerate if not set)
	[[ ${tasks_install["ca"]} ]] && xbi_setPassword ca
}

#-------------------------------------------------------------------------------
# Show dialogs for ispconfig-kickstarter
#-------------------------------------------------------------------------------
function ispckickstarter_dialog_show() {
	case ${1} in
		aptSource )
			# Userinput: Apt-source
			aptSource=$(${whiptail} --backtitle "$(xbi_label pluginTitle)" --inputbox "$(xbi_label dialog_${1}_message)" 8 78 ${!1} --title "$(xbi_label dialog_${1}_title)" 3>&1 1>&2 2>&3)
			;;
		hostname )
			# Userinput: Hostname
			hostname=$(${whiptail} --backtitle "$(xbi_label pluginTitle)" --inputbox "$(xbi_label dialog_${1}_message)" 8 78 ${!1} --title "$(xbi_label dialog_${1}_title)" 3>&1 1>&2 2>&3)
			;;
		ipAddress )
			# Userinput: IP-address
			ipAddress=$(${whiptail} --backtitle "$(xbi_label pluginTitle)" --inputbox "$(xbi_label dialog_${1}_message)" 8 78 ${!1} --title "$(xbi_label dialog_${1}_title)" 3>&1 1>&2 2>&3)
			;;
		timeServer )
			# Userinput: time-server
			timeServer=$(${whiptail} --backtitle "$(xbi_label pluginTitle)" --inputbox "$(xbi_label dialog_${1}_message)" 8 78 ${!1} --title "$(xbi_label dialog_${1}_title)" 3>&1 1>&2 2>&3)
			;;
		defaultWebServer )
			# Userinput: webserver
			selected_nginx="OFF"
			selected_apache2="OFF"
			[ "${defaultWebServer}" = "nginx" ] && selected_nginx="ON"
			[ "${defaultWebServer}" = "apache2" ] && selected_apache2="ON"
			defaultWebServer=$(${whiptail} --backtitle "$(xbi_label pluginTitle)" --radiolist "$(xbi_label dialog_${1}_message)" 8 78 2 --title "$(xbi_label dialog_${1}_title)" "nginx" "" ${selected_nginx} "apache2" "" ${selected_apache2} 3>&1 1>&2 2>&3)
			;;
		dateTimeZone )
			# Userinput: Current timezone
			dateTimeZone=$(${whiptail} --backtitle "$(xbi_label pluginTitle)" --inputbox "$(xbi_label dialog_${1}_message)" 8 78 ${!1} --title "$(xbi_label dialog_${1}_title)" 3>&1 1>&2 2>&3)
			;;
		systemEmailAddress )
			# Userinput: System-E-Mail
			systemEmailAddress=$(${whiptail} --backtitle "$(xbi_label pluginTitle)" --inputbox "$(xbi_label dialog_${1}_message)" 12 78 "${!1}" --title "$(xbi_label dialog_${1}_title)" 3>&1 1>&2 2>&3)
			;;
		ca_countryName )
			# Userinput: CA->Country
			ca_countryName=$(${whiptail} --backtitle "$(xbi_label pluginTitle)" --inputbox "$(xbi_label dialog_${1}_message)" 12 78 ${!1} --title "$(xbi_label dialog_${1}_title)" 3>&1 1>&2 2>&3)
			;;
		ca_commonName )
			# Userinput: CA->Common name
			ca_commonName=$(${whiptail} --backtitle "$(xbi_label pluginTitle)" --inputbox "$(xbi_label dialog_${1}_message)" 12 78 "${!1}" --title "$(xbi_label dialog_${1}_title)" 3>&1 1>&2 2>&3)
			;;
		ca_organizationName )
			# Userinput: CA->Organization
			ca_organizationName=$(${whiptail} --backtitle "$(xbi_label pluginTitle)" --inputbox "$(xbi_label dialog_${1}_message)" 12 78 "${!1}" --title "$(xbi_label dialog_${1}_title)" 3>&1 1>&2 2>&3)
			;;
		ssl_countryName )
			# Userinput: SSL->Country
			ssl_countryName=$(${whiptail} --backtitle "$(xbi_label pluginTitle)" --inputbox "$(xbi_label dialog_${1}_message)" 12 78 ${!1} --title "$(xbi_label dialog_${1}_title)" 3>&1 1>&2 2>&3)
			;;
		ssl_stateOrProvinceName )
			# Userinput: SSL->State
			ssl_stateOrProvinceName=$(${whiptail} --backtitle "$(xbi_label pluginTitle)" --inputbox "$(xbi_label dialog_${1}_message)" 12 78 "${!1}" --title "$(xbi_label dialog_${1}_title)" 3>&1 1>&2 2>&3)
			;;
		ssl_localityName )
			# Userinput: SSL->City
			ssl_localityName=$(${whiptail} --backtitle "$(xbi_label pluginTitle)" --inputbox "$(xbi_label dialog_${1}_message)" 12 78 "${!1}" --title "$(xbi_label dialog_${1}_title)" 3>&1 1>&2 2>&3)
			;;
		ssl_organizationName )
			# Userinput: SSL->Organization
			ssl_organizationName=$(${whiptail} --backtitle "$(xbi_label pluginTitle)" --inputbox "$(xbi_label dialog_${1}_message)" 12 78 "${!1}" --title "$(xbi_label dialog_${1}_title)" 3>&1 1>&2 2>&3)
			;;
		ssl_organizationalUnitName )
			# Userinput: SSL->Organizational Unit
			ssl_organizationalUnitName=$(${whiptail} --backtitle "$(xbi_label pluginTitle)" --inputbox "$(xbi_label dialog_${1}_message)" 12 78 "${!1}" --title "$(xbi_label dialog_${1}_title)" 3>&1 1>&2 2>&3)
			;;
		ssl_commonName )
			# Userinput: SSL->Common name
			ssl_commonName=$(${whiptail} --backtitle "$(xbi_label pluginTitle)" --inputbox "$(xbi_label dialog_${1}_message)" 12 78 "${!1}" --title "$(xbi_label dialog_${1}_title)" 3>&1 1>&2 2>&3)
			;;
		ssl_email )
			# Userinput: SSL->email
			ssl_email=$(${whiptail} --backtitle "$(xbi_label pluginTitle)" --inputbox "$(xbi_label dialog_${1}_message)" 12 78 ${!1} --title "$(xbi_label dialog_${1}_title)" 3>&1 1>&2 2>&3)
			;;
		password_mysql )
			# Userinput: MySQL-root-password
			dialog_checkPassword "password_mysql"
			;;
		password_ispconfig )
			# Userinput: ISPConfig admin-password
			dialog_checkPassword "password_ispconfig"
			;;
		password_mailinglist )
			# Userinput: Mailinglist admin-password
			dialog_checkPassword "password_mailinglist"
			;;
		password_roundcube )
			# Userinput: Roundcube admin-password
			dialog_checkPassword "password_roundcube"
			;;
		password_ca )
			# Userinput: Password for certificate-authority
			dialog_checkPassword "password_ca"
			;;
	esac
	[ $? -eq 0 ] || xbi_exitOnUser
}

#-------------------------------------------------------------------------------
# Output a brief summary of the user-input
#-------------------------------------------------------------------------------
function ispckickstarter_view_userVariables() {

	declare -a msgArray=()

	# Output common information
	if [[ ${tasks_install["apt"]} ]]; then
		msgArray[0]="$(echo_variable aptSource)"
	fi
	if
		[[ ${tasks_install["hostname"]} ]] ||
		[[ ${tasks_install["mail"]} ]] ||
		[[ ${tasks_install["monitoring"]} ]] ||
		[[ ${tasks_install["ispconfig"]} ]] ||
		[[ ${tasks_install["ca"]} ]] ||
		[[ ${tasks_install["secure"]} ]];
	then
		msgArray[1]="$(echo_variable hostname)"
	fi
	if
		[[ ${tasks_install["network"]} ]] ||
		[[ ${tasks_install["hostname"]} ]] ||
		[[ ${tasks_install["monitoring"]} ]];
	then
		msgArray[2]="$(echo_variable ipAddress)"
	fi
	if [[ ${tasks_install["ntp"]} ]]; then
		msgArray[3]="$(echo_variable timeServer)"
	fi

	if
		( [[ ${tasks_install["nginx"]} ]] && [[ ${tasks_install["apache2"]} ]] ) ||
		( [[ ${tasks_install["nginx"]} ]] && [[ $(xbi_isInstalled "apache2") -eq 0 ]] ) ||
		( [[ ${tasks_install["apache2"]} ]] && [[ $(xbi_isInstalled "nginx") -eq 0 ]] ) ||
		( [[ $(xbi_isInstalled "nginx") -eq 0 ]] && [[ $(xbi_isInstalled "apache2") -eq 0 ]] );
	then
		msgArray[4]="$(echo_variable defaultWebServer)"
	fi
	if [[ ${tasks_install["nginx"]} ]] || [[ ${tasks_install["apache2"]} ]]; then
		msgArray[5]="$(echo_variable dateTimeZone)"
	fi
	if
		[[ ${tasks_install["mailinglist"]} ]] ||
		[[ ${tasks_install["ispconfig"]} ]] ||
		[[ ${tasks_install["ca"]} ]] ||
		[[ ${tasks_install["secure"]} ]];
	then
		msgArray[6]="$(echo_variable systemEmailAddress)"
	fi
	if [ ${#msgArray[@]} -gt 0 ]; then
		echo_subheader "$(xbi_label view_title_common)"
		for i in "${msgArray[@]}"; do echo "${i}"; done
	fi

	# Output CA-informations
	msgArray=()
	if [[ ${tasks_install["ca"]} ]]; then
		msgArray[0]="$(echo_variable ca_countryName)"
		[[ ${ca_stateOrProvinceName} ]] && msgArray[1]="$(echo_variable ca_stateOrProvinceName)"
		[[ ${ca_localityName} ]] && msgArray[2]="$(echo_variable ca_localityName)"
		msgArray[3]="$(echo_variable ca_organizationName)"
		[[ ${ca_organizationalUnitName} ]] && msgArray[4]="$(echo_variable ca_organizationalUnitName)"
		msgArray[5]="$(echo_variable ca_commonName)"
		[[ ${ca_email} ]] && msgArray[6]="$(echo_variable ca_email)"
	fi
	if [ ${#msgArray[@]} -gt 0 ]; then
		echo_subheader "$(xbi_label view_title_ca)"
		for i in "${msgArray[@]}"; do echo "${i}"; done
	fi

	# Output SSL-informations
	msgArray=()
	if
		[[ ${tasks_install["ftp"]} ]] ||
		[[ ${tasks_install["mail"]} ]] ||
		[[ ${tasks_install["ispconfig"]} ]] ||
		[[ ${tasks_install["ca"]} ]] ||
		[[ ${tasks_install["secure"]} ]];
	then
		msgArray[0]="$(echo_variable ssl_countryName)"
		msgArray[1]="$(echo_variable ssl_stateOrProvinceName)"
		msgArray[2]="$(echo_variable ssl_localityName)"
		msgArray[3]="$(echo_variable ssl_organizationName)"
		msgArray[4]="$(echo_variable ssl_organizationalUnitName)"
		msgArray[5]="$(echo_variable ssl_commonName)"
		msgArray[6]="$(echo_variable ssl_email)"
	fi
	if [ ${#msgArray[@]} -gt 0 ]; then
		echo_subheader "$(xbi_label view_title_ssl)"
		for i in "${msgArray[@]}"; do echo "${i}"; done
	fi

	# Output passwords
	if [ ${showPasswordsInSummary} -eq 1 ]; then
		msgArray=()
		if
			[[ ${tasks_install["mysql"]} ]] ||
			[[ ${tasks_install["ispconfig"]} ]] ||
			[[ ${tasks_install["phpmyadmin"]} ]] ||
			[[ ${tasks_install["roundcube"]} ]];
		then
			msgArray[0]="$(echo_variable password_mysql)"
		fi
		[[ ${tasks_install["ispconfig"]} ]] && msgArray[1]="$(echo_variable password_ispconfig)"
		[[ ${tasks_install["mailinglist"]} ]] && msgArray[2]="$(echo_variable password_mailinglist)"
		[[ ${tasks_install["roundcube"]} ]] && msgArray[3]="$(echo_variable password_roundcube)"
		[[ ${tasks_install["ca"]} ]] && msgArray[4]="$(echo_variable password_ca)"
		if [ ${#msgArray[@]} -gt 0 ]; then
			echo_subheader "$(xbi_label view_title_passwords)"
			for i in "${msgArray[@]}"; do echo "${i}"; done
		fi
	fi
}



################################################################################
# Bootstrap
################################################################################

# Read passwords from external file
[ -r ${passwdFile} ] && . ${passwdFile}
# Read configuration file for automated install
[ -r ${confFile} ] && . ${confFile}
# Run installer
xbi_bootstrap ${1}
