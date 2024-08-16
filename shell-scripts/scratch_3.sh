#!/bin/bash
curl "https://getcomposer.org/installer" > composer-install.php
chmod +x composer-install.php
php composer-install.php
sudo mv composer.phar /usr/local/bin/composer
sudo mkdir /opt/drupal
sudo chown www-data:www-data /opt/drupal
sudo chmod 775 /opt/drupal
sudo chown -R www-data:www-data /var/www/
