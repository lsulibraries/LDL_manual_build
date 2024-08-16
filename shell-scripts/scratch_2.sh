#!/bin/bash
sudo apt -y install php8.3 php8.3-cli php8.3-common php8.3-curl php8.3-dev php8.3-gd php8.3-imap php8.3-mbstring php8.3-opcache php8.3-xml php8.3-yaml php8.3-zip libapache2-mod-php8.3 php-pgsql php-redis php-xdebug unzip
sudo a2enmod php8.3
sudo systemctl restart apache2
# set default php to the version we have insalled:
sudo update-alternatives --set php /usr/bin/php8.3
#install Postgresql
sudo apt install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
sudo apt install -y postgresql-15
# Upgrade:
sudo apt-get upgrade