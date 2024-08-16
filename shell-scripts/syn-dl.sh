#!/bin/bash
sudo wget -P /opt/tomcat/lib https://github.com/Islandora/Syn/releases/download/v1.1.1/islandora-syn-1.1.1-all.jar
sudo chown -R tomcat:tomcat /opt/tomcat/lib
sudo chmod -R 640 /opt/tomcat/lib
