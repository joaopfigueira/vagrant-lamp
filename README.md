Provisioning Vagrant with a LAMP server
=======================================

Requires VirtualBox and Vagrant installed on your system.

You can use this box as a starting point to your PHP projects.

### Instalation

```
$ composer create-project joaofigueira/vagrant_lamp path --prefer-dist
```

### Usage:

```
$ vagrant up
```

### Configuration

You can choose what you want to install by editing the file `provision/bootstrap.sh`

Currently there are options for:
- Apache
- PHP
- Composer
- PHPUnit
- MySql
- phpMyAdmin
- MailCatcher
- Git
- Node
- Gulp
- Bower
- Grunt

You can flag the software to be installed by setting true or false. example:

```
USE_PHPMYADMIN=true/false
```

### MySql and phpMyAdmin

If you choose to install MySql, and set `MYSQL_IMPORT` to true, you can place a `sql` file inside `provision/` and that sql will be imported to the database you chose in `DB_NAME`

### Git

If you choose to install Git, use `GIT_USER`and `GIT_EMAIL` to setup Git.

Have fun!
