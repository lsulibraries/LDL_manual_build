#!/bin/bash
#scratch_6
#check your cantaloupe version
sudo wget -O /opt/cantaloupe.zip https://github.com/cantaloupe-project/cantaloupe/releases/download/v5.0.6/cantaloupe-5.0.6.zip
sudo unzip /opt/cantaloupe.zip
sudo mkdir /opt/cantaloupe_config
sudo cp cantaloupe-5.0.6/cantaloupe.properties.sample /opt/cantaloupe_config/cantaloupe.properties
sudo cp cantaloupe-5.0.6/delegates.rb.sample /opt/cantaloupe_config/delegates.rb
sudo cp /mnt/shared/configs/cantaloupe/cantaloupe.service /etc/systemd/system/
sudo chmod 755 /etc/systemd/system/cantaloupe.service
sudo systemctl enable cantaloupe
sudo systemctl start cantaloupe
