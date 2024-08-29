#!/bin/bash
sudo cp /mnt/shared/configs/crayfish_configs/Houdini/config /opt/crayfish/Houdini
mkdir -p /opt/crayfish/Houdini/var/cache/dev
sudo chown -R www-data:www-data /opt/crayfish/Houdini
sudo chmod -R 755 /opt/crayfish/Houdini

sudo cp /mnt/shared/configs/crayfish_configs/Homarus /opt/crayfish/Homarus
mkdir -p /opt/crayfish/Homarus/var/cache/dev
sudo chown -R www-data:www-data /opt/crayfish/Homarus
sudo chmod -R 755 /opt/crayfish/Homarus

sudo cp /mnt/shared/configs/crayfish_configs/Hypercube /opt/crayfish/Hypercube
mkdir -p /opt/crayfish/Hypercube/var/cache/dev
sudo chown -R www-data:www-data /opt/crayfish/Hypercube
sudo chmod -R 755 /opt/crayfish/Hypercube

sudo cp /mnt/shared/configs/crayfish_configs/Milliner /opt/crayfish/Milliner
mkdir -p /opt/crayfish/Hypercube/var/cache/dev
sudo chown -R www-data:www-data /opt/crayfish/Milliner
sudo chmod -R 755 /opt/crayfish/Milliner

sudo cp /mnt/shared/configs/crayfish_configs/CrayFits /opt/crayfish/CrayFits
sudo mkdir -p /opt/crayfish/CrayFits/var/cache/dev
sudo chown -R www-data:www-data /opt/crayfish/CrayFits
sudo chmod -R 755 /opt/crayfish/CrayFits

sudo cp /mnt/shared/configs/crayfish_configs/Recast /opt/crayfish/Recast
mkdir -p /opt/crayfish/Recast/var/cache/dev
sudo chown -R www-data:www-data /opt/crayfish/Recast
sudo chmod -R 755 /opt/crayfish/Recast
