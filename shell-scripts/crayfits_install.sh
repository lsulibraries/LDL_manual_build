#!/bin/bash
sudo mkdir /opt/crayfish/CrayFits
cd /opt
sudo wget https://github.com/harvard-lts/fits/releases/download/1.5.1/fits-1.5.1.zip
sudo unzip -d fits-1.5.1.zip /opt/crayfish/CrayFits 
sudo wget https://projects.iq.harvard.edu/files/fits/files/fits-1.2.1.war 
mv fits-1.2.1.war /opt/tomcat/webapps/fits.war
chmod 755 /opt/tomcat/webapps/fits.war
echo -e "fits.home=/opt/fits\n\nshared.loader=/opt/fits/lib/*.jar" | sudo tee -a /opt/tomcat/conf/catalina.properties