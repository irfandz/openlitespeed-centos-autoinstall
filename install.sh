#!/bin/bash

# Random Password Generator
TEMPRANDSTR=
function getRandPassword
{
    dd if=/dev/urandom bs=8 count=1 of=/tmp/randpasswdtmpfile >/dev/null 2>&1
    TEMPRANDSTR=`cat /tmp/randpasswdtmpfile`
    rm /tmp/randpasswdtmpfile
    local DATE=`date`
    TEMPRANDSTR=`echo "$TEMPRANDSTR$RANDOM$DATE" |  md5sum | base64 | head -c 32`
}
getRandPassword
ROOTSQLPWD=$TEMPRANDSTR
PMABLOWFISH=$TEMPRANDSTR

# Define short code
GITRAW=https://raw.githubusercontent.com/irfandz/openlitespeed-centos-autoinstall/master
LSWSDIR=/usr/local/lsws

# Update
yum -y install epel-release
yum -y install wget certbot openssl
#wget -O /etc/yum.repos.d/MariaDB.repo $GITRAW/repo/MariaDB.repo
bash $GITRAW/repo/mariadb_repo_setup
#to avoid conflict with the OS-vendor packages, install dependencies separately and use the --repo flag to specify the repository:
sudo yum -y install perl-DBI libaio libsepol lsof boost-program-options
sudo yum -y install --repo="mariadb-main" MariaDB-server
#rpm -ivh http://rpms.litespeedtech.com/centos/litespeed-repo-1.1-1.el7.noarch.rpm
rpm -ivh http://rpms.litespeedtech.com/centos/litespeed-repo-1.1-1.el8.noarch.rpm
yum -y update

# Install Proftpd
yum -y install proftpd
sed -i "s/ProFTPD server/$HOSTNAME/g" /etc/proftpd.conf

#Install Openlitespeed & MariaDB
mkdir /home/defdomain
mkdir /home/defdomain/html
mkdir /home/defdomain/logs
yum -y install openlitespeed
sudo yum -y install mariadb-server mariadb-client

# Install PHP 73
yum -y install lsphp73 lsphp73-common lsphp73-mysqlnd lsphp73-process lsphp73-gd lsphp73-mbstring \
lsphp73-mcrypt lsphp73-opcache lsphp73-bcmath lsphp73-pdo lsphp73-xml lsphp73-json lsphp73-zip lsphp73-xmlrpc lsphp73-pecl-mcrypt

#Setting Up
touch $LSWSDIR/domain
mv -f $LSWSDIR/conf/vhosts/Example/ $LSWSDIR/conf/vhosts/defdomain/
rm -f $LSWSDIR/conf/vhosts/defdomain/vhconf.conf
rm -f $LSWSDIR/conf/httpd_config.conf
rm -f $LSWSDIR/admin/conf/admin_config.conf
wget -O $LSWSDIR/conf/vhosts/defdomain/vhconf.conf $GITRAW/conf/vhconf.conf
wget -O $LSWSDIR/conf/httpd_config.conf $GITRAW/conf/httpd_config.conf
wget -O $LSWSDIR/admin/conf/admin_config.conf $GITRAW/conf/admin_config.conf
chown lsadm:lsadm $LSWSDIR/conf/vhosts/defdomain/vhconf.conf
chown lsadm:lsadm $LSWSDIR/conf/httpd_config.conf
chown lsadm:lsadm $LSWSDIR/admin/conf/admin_config.conf

# Copy Script
mkdir /scripts
wget -O /scripts/lscreate $GITRAW/scripts/lscreate
wget -O /scripts/lsremove $GITRAW/scripts/lsremove
wget -O /scripts/certbot $GITRAW/scripts/certbot
wget -O /scripts/createdb $GITRAW/scripts/createdb
wget -O /usr/bin/lsws $GITRAW/scripts/lsws
chmod +x /usr/bin/lsws
chmod +x /scripts/*

#Copy Templates
wget -O $LSWSDIR/conf/templates/incl.conf $GITRAW/templates/incl.conf
wget -O $LSWSDIR/conf/templates/vhconf.conf $GITRAW/templates/vhconf.conf

# Create Content in Homedir and logs
touch /home/defdomain/html/.htaccess
touch /home/defdomain/logs/{error.log,access.log}
cat << EOT > /home/defdomain/html/index.php
<?php
echo "Its Works!";
?>
EOT
chown -R nobody:nobody /home/defdomain/html/

# Installing PHPMYAdmin
mkdir $LSWSDIR/pma
mkdir $LSWSDIR/pma/{html,logs}
mkdir $LSWSDIR/conf/vhosts/pma
mkdir $LSWSDIR/conf/cert/pma
touch $LSWSDIR/pma/logs/error.log
touch $LSWSDIR/pma/logs/access.log
wget -O $LSWSDIR/conf/vhosts/pma/vhconf.conf $GITRAW/conf/pma_vhconf.conf
wget --no-check-certificate -O $LSWSDIR/pma/html/pma.tar.gz https://files.phpmyadmin.net/phpMyAdmin/4.8.2/phpMyAdmin-4.8.2-english.tar.gz
cd $LSWSDIR/pma/html/
tar -xzvf pma.tar.gz
mv phpMyAdmin-4.8.2-english/* ./
wget -O config.inc.php $GITRAW/conf/config.inc.php
sed -i "s/#BLOWFISH#/$PMABLOWFISH/g" config.inc.php
mkdir tmp
rm -f pma.tar.gz && rm -rf phpMyAdmin-4.8.2-english
cd /
chown -R lsadm:lsadm $LSWSDIR/pma/

# Generate cerificare for PMA
openssl genrsa -out $LSWSDIR/conf/cert/pma/pma.key 2048
openssl rsa -in $LSWSDIR/conf/cert/pma/pma.key -out $LSWSDIR/conf/cert/pma/pma.key
openssl req -sha256 -new -key $LSWSDIR/conf/cert/pma/pma.key -out $LSWSDIR/conf/cert/pma/pma.csr -subj "/CN=localhost"
openssl x509 -req -sha256 -days 365 -in $LSWSDIR/conf/cert/pma/pma.csr -signkey $LSWSDIR/conf/cert/pma/pma.key -out $LSWSDIR/conf/cert/pma/pma.crt

# Open port Needed in Firewall
firewall-cmd --zone=public --permanent --add-port=21/tcp
firewall-cmd --zone=public --permanent --add-port=80/tcp
firewall-cmd --zone=public --permanent --add-port=443/tcp
firewall-cmd --zone=public --permanent --add-port=7080/tcp
firewall-cmd --zone=public --permanent --add-port=8090/tcp
firewall-cmd --reload

# Generate SSL for Webadmin
mkdir $LSWSDIR/conf/cert/admin
openssl genrsa -out $LSWSDIR/conf/cert/admin/admin.key 2048
openssl rsa -in $LSWSDIR/conf/cert/admin/admin.key -out $LSWSDIR/conf/cert/admin/admin.key
openssl req -sha256 -new -key $LSWSDIR/conf/cert/admin/admin.key -out $LSWSDIR/conf/cert/admin/admin.csr -subj "/CN=localhost"
openssl x509 -req -sha256 -days 365 -in $LSWSDIR/conf/cert/admin/admin.csr -signkey $LSWSDIR/conf/cert/admin/admin.key -out $LSWSDIR/conf/cert/admin/admin.crt

#Setting MySQL
systemctl start mariadb && systemctl start proftpd && $LSWSDIR/bin/lswsctrl start
mysql -uroot -v -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -uroot -v -e "DROP DATABASE test;"
mysql -uroot -v -e "DELETE FROM mysql.user WHERE User='';"
mysql -uroot -v -e "use mysql;update user set Password=PASSWORD('$ROOTSQLPWD') where user='root'; flush privileges;"

# Save Password root MariaDB
cat << EOT > /root/.MariaDB
$ROOTSQLPWD
EOT

# Create PHP symlink
ln -s /usr/local/lsws/lsphp73/bin/lsphp /usr/bin/php

systemctl enable proftpd
systemctl enable mariadb
