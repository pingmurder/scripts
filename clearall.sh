#!/bin/bash
#Emtpy all error logs
find /home*/ -name error_log -type f -print -exec truncate --size 0 "{}" \;
#Remove core dumps
find /home*/ -type f -regex ".*/core\.[0-9]*$" -exec rm -v {} \;
#Remove EasyApache files
rm -rfv /home*/cpeasyapache
#Remove Softaculous backups
rm -fv /home**/*/.softaculous/backups/*
rm -rfv /home**/*/softaculous_backups/*
#Remove account backups
for user in `/bin/ls -A /var/cpanel/users` ; do rm -fv /home*/$user/backup-*$user.tar.gz ; done
#Remove Fantastico backups
rm -rfv /home*/*/fantastico_backups
#Remove temporary cPanel files
rm -fv /home*/*/tmp/Cpanel_*
#Remove any cpmove files
rm -rvf /home*/cpmove-*
#Remove temporary account migration files
rm -rvf /home**/cpanelpkgrestore.TMP*
#Reduce log usage
rm -fv /var/log/*.gz
rm -fv /var/log/*201*
#Remove old Apache files
rm -rfv /usr/local/apache.backup*
truncate -s 0 /var/log/apache2/*_log
truncate -s 0 /var/log/apache2/*log
rm -rfv /var/log/apache2/*.gz
truncate -s 0 /var/log/apache2/domlogs/*
truncate -s 0 /var/log/apache2/domlogs/*/*
#Remove old maldet files
rm -rfv /usr/local/maldet.bk*
#Remove maldet logs
rm -fv /usr/local/maldetect/logs/*
#Remove archived cPanel logs
rm -fv /usr/local/cpanel/logs/archive/*.gz
#Remove archived Apache logs
rm -fv /usr/local/apache/logs/*.gz
rm -fv /usr/local/apache/logs/archive/*.gz
#Restart apache
service httpd restart
