#!/bin/bash
sudo mkdir /opt/crayfish/Commons
cd /opt/crayfish/Commons
sudo chown -R www-data:www-data /opt/crayfish/Commons
sudo chmod -R 755 /opt/crayfish/Commons
sudo -u www-data:www-data composer require islandora/crayfish-commons
