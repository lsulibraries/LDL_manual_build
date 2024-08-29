#!/bin/bash
sudo mkdir /opt/keys
sudo openssl genrsa -out "/opt/keys/syn_private.key" 2048
sudo openssl rsa -pubout -in "/opt/keys/syn_private.key" -out "/opt/keys/syn_public.key"
sudo chown www-data:www-data /opt/keys/syn*
sudo mkdir /opt/syn
sudo cp /mnt/shared/configs/fedora_configs/tomcat-and-syn-for-fedora/syn-settings.xml /mnt/fcrepo/config/
sudo chown tomcat:tomcat /mnt/fcrepo/config/syn-settings.xml
sudo chmod 640 /mnt/fcrepo/config/syn-settings.xml
