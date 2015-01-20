#!/bin/bash

echo "Updating ..."
apt-get update > /dev/null

echo "Installing Apache"
apt-get install -y apache2 > /dev/null
cp -f /vagrant/provision/000-default.conf /etc/apache2/sites-available/000-default.conf
a2enmod rewrite >/dev/null
cp -f /vagrant/provision/servername.conf /etc/apache2/conf-available/servername.conf
a2enconf servername > /dev/null
service apache2 restart > /dev/null

echo "Installing PHP"
apt-get install -y php5 libapache2-mod-php5 > /dev/null
apt-get install -y php5-curl > /dev/null
apt-get install -y php5-gd > /dev/null
apt-get install -y php5-sqlite > /dev/null
apt-get install -y php5-mcrypt > /dev/null
php5enmod mcrypt
cp -f /vagrant/provision/php.ini /etc/php5/apache2/php.ini
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

echo "Installing PHPUnit"
wget -q https://phar.phpunit.de/phpunit.phar 
chmod +x phpunit.phar
mv phpunit.phar /usr/local/bin/phpunit

echo "Installing Node.js and npm"
apt-get install -y nodejs > /dev/null
ln -s /usr/bin/nodejs /usr/bin/node
apt-get install -y npm > /dev/null

echo "Installing gulp, bower and grunt"
npm install -g gulp --silent > /dev/null
npm install -g bower --silent > /dev/null
npm install -g grunt-cli --silent > /dev/null

service apache2 restart > /dev/null

echo "Done Installing stuff. Have a nice day!"
