#!/bin/bash
sudo cp /mnt/shared/configs/crayfish_configs/crayfish.conf /etc/apache2/sites-available
sudo a2ensite crayfish.conf
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod headers
echo "Listen 8000" | sudo tee -a /etc/apache2/ports.conf
sudo systemctl restart apache2
