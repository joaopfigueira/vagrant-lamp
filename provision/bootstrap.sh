#!/bin/bash

###
# bootstrap.sh
#
# configuration variables
###

USE_APACHE=true

# PHP stuff
USE_PHP=true
USE_COMPOSER=true
COMPOSER_AUTO=false
USE_PHPUNIT=true

# Database stuff
USE_MYSQL=true
USE_PHPMYADMIN=true
DB_HOST=localhost
DB_NAME=projectdb
DB_USER=root
DB_PASSWD=root
MYSQL_IMPORT=true

#Git stuff
USE_GIT=true
GIT_USER="Git User"
GIT_EMAIL=user.email@domain.com

# Node stuff
USE_NODE=false
USE_GULP=false
USE_BOWER=false
USE_GRUNT=false

USE_MAILCATCHER=false

###
# end configuration
###

echo "Creating swap file"
/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024 > /dev/null 2>&1
/sbin/mkswap /var/swap.1 > /dev/null 2>&1
/sbin/swapon /var/swap.1 > /dev/null 2>&1
echo '/var/swap.1 none swap sw 0 0' >> /etc/fstab

echo "Updating ..."
apt-get -qq update > /dev/null 2>&1

sed -i 's|\\u@\\h:\\w\\$ |\\n\\u@\\h:\\w\\n\\$ |g' /home/vagrant/.bashrc

if $USE_APACHE; then
    echo "Installing Apache"
    apt-get -qq -y install apache2 > /dev/null 2>&1
    cp -f /vagrant/provision/000-default.conf /etc/apache2/sites-available/000-default.conf
    a2enmod rewrite > /dev/null 2>&1
    cp -f /vagrant/provision/servername.conf /etc/apache2/conf-available/servername.conf
    a2enconf servername > /dev/null 2>&1
    service apache2 restart > /dev/null 2>&1
fi

if $USE_PHP; then
    echo "Installing PHP"
    apt-get -qq -y install php5 libapache2-mod-php5 > /dev/null 2>&1
    apt-get -qq -y install php5-curl > /dev/null 2>&1
    apt-get -qq -y install php5-gd > /dev/null 2>&1
    apt-get -qq -y install php5-sqlite > /dev/null 2>&1
    apt-get -qq -y install php5-mcrypt > /dev/null 2>&1
    php5enmod mcrypt
    cp -f /vagrant/provision/php.ini /etc/php5/apache2/php.ini
fi

if $USE_MYSQL; then
    echo "Installing MySQL"
    debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_PASSWD"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_PASSWD"
    apt-get -qq -y install mysql-server > /dev/null 2>&1
    apt-get -qq -y install mysql-client php5-mysql > /dev/null  2>&1

    echo "Creating Database"
    mysql -uroot -p$DB_PASSWD -e "CREATE DATABASE $DB_NAME" >> /dev/null 2>&1
    mysql -uroot -p$DB_PASSWD -e "grant all privileges on $DB_NAME.* to '$DB_USER'@'localhost' identified by '$DB_PASSWD'" > /dev/null 2>&1    

    if $MYSQL_IMPORT && [ -f /vagrant/provision/sql ]; then
        echo "SQL file found. Importing Database"
        mysql -u $DB_USER -p$DB_PASSWD $DB_NAME < /vagrant/provision/sql
    fi
fi

if $USE_PHPMYADMIN && $USE_APACHE; then
    echo "Installing phpMyAdmin"
    debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
    debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $DB_PASSWD"
    debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $DB_PASSWD"
    debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $DB_PASSWD"
    debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
    apt-get -qq -y install phpmyadmin > /dev/null 2>&1
fi

if $USE_COMPOSER; then
    echo "Installing Composer"
    curl -sS https://getcomposer.org/installer | php > /dev/null 2>&1
    mv composer.phar /usr/local/bin/composer
fi

if $COMPOSER_AUTO && [ -f /vagrant/composer.json ]; then
    echo "composer.json found, let's setup your project"
    composer --working-dir=/vagrant/ install
fi

if $USE_GIT; then
    echo "Installing Git"
    apt-get install -y git > /dev/null 2>&1
    
    echo "[user]" >> /home/vagrant/.gitconfig
    echo "    name = $GIT_USER" >> /home/vagrant/.gitconfig
    echo "    email = $GIT_EMAIL" >> /home/vagrant/.gitconfig
fi

if $USE_PHPUNIT; then
    echo "Installing PHPUnit"
    wget -q https://phar.phpunit.de/phpunit.phar 
    chmod +x phpunit.phar
    mv phpunit.phar /usr/local/bin/phpunit
fi

if $USE_NODE; then
    echo "Installing Node.js and npm"
    apt-get install -y nodejs > /dev/null 2>&1
    ln -s /usr/bin/nodejs /usr/bin/node
    apt-get install -y npm > /dev/null 2>&1
fi

if $USE_GULP && $USE_NODE; then
    echo "Installing Gulp"
    npm install --global gulp-cli --silent > /dev/null 2>&1
fi

if $USE_BOWER && $USE_NODE; then
    echo "Installing Bower"
    npm install -g bower --silent > /dev/null 2>&1
fi

if $USE_GRUNT && $USE_NODE; then
    echo "Installing Grunt"
    npm install -g grunt-cli --silent > /dev/null 2>&1
fi

if $USE_MAILCATCHER; then
    apt-get -qq -y install build-essential libsqlite3-dev ruby1.9.1-dev > /dev/null 2>&1
    gem install mime-types --version "< 3" > /dev/null 2>&1
    gem install --conservative mailcatcher > /dev/null 2>&1
    echo 'description "Mailcatcher"' > /etc/init/mailcatcher.conf
    echo '' >> /etc/init/mailcatcher.conf
    echo 'start on runlevel [2345]' >> /etc/init/mailcatcher.conf
    echo 'stop on runlevel [2345]' >> /etc/init/mailcatcher.conf
    echo '' >> /etc/init/mailcatcher.conf
    echo 'respawn' >> /etc/init/mailcatcher.conf
    echo 'exec /usr/bin/env $(which mailcatcher) --foreground --http-ip=0.0.0.0' >> /etc/init/mailcatcher.conf
    if $USE_PHP; then
        sed -i 's|^;sendmail_path =|sendmail_path = /usr/bin/env /usr/local/bin/catchmail|g' /etc/php5/apache2/php.ini
    fi
    /usr/bin/env $(which mailcatcher) --ip=0.0.0.0 > /dev/null 2>&1
fi

if $USE_APACHE; then
    service apache2 restart > /dev/null 2>&1
fi

echo "Done Installing stuff. Have a nice day!"
