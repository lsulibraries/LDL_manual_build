#!/bin/bash
#scratch_5 / tomcat configuration
#Make sure version of openjdk java is correct in JAVA_HOME:
sudo cp /mnt/shared/configs/tomcat_conf/setenv.sh /opt/tomcat/bin/
sudo chmod 755 /opt/tomcat/bin/setenv.sh
sudo cp /mnt/shared/configs/tomcat_conf/tomcat.service /etc/systemd/system/
sudo chmod 755 /etc/systemd/system/tomcat.service
sudo systemctl start tomcat
sudo systemctl enable tomcat
sudo systemctl status tomcat
