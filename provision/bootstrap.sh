#!/bin/bash

echo "Updating ..."
apt-get update > /dev/null

echo "Installing Apache"
apt-get install -y apache2 php5 libapache2-mod-php5 > /dev/null
apt-get install -y php5-mcrypt > /dev/null

echo "Configuring Apache..."
cp -f /vagrant/provision/000-default.conf /etc/apache2/sites-available/000-default.conf
a2enmod rewrite >/dev/null
cp -f /vagrant/provision/servername.conf /etc/apache2/conf-available/servername.conf
a2enconf servername > /dev/null
php5enmod mcrypt
service apache2 restart > /dev/null

echo "Installing MySQL"
debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
apt-get -y install mysql-server > /dev/null

apt-get install -y mysql-client php5-mysql > /dev/null

echo "Installing Composer"
curl -sS https://getcomposer.org/installer | php > /dev/null
mv composer.phar /usr/local/bin/composer

echo "Installing Git"
apt-get install -y git > /dev/null

if [ -f /vagrant/composer.json ]; then
    echo "composer.json found, let's setup your project"
    composer --working-dir=/vagrant/ install
fi

echo "Done Installing stuff. Have a nice day!"
