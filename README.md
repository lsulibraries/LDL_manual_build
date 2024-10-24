# Pre-BUILD Requirements

- download vmware
- https://www.vmware.com/products/workstation-pro/workstation-pro-evaluation.html
- LSU has a way to get a license: https://software.grok.lsu.edu/Article.aspx?articleId=20512
- LSU OneDrive link to [shared](https://lsumail2.sharepoint.com/:f:/r/sites/Team-LIB/Shared%20Documents/Departments/Technology%20Initiatives/LDL/LDL-2/build_instructions_for_vmware/shared?csf=1&web=1&e=Ht4TtV)

- create a vmware machine 
- choose ubuntu server 22.04 iso 
- 100 GB on one file for disk size 
- the vm must have network access (right click the vm, go to settings>network adapter, select "Bridged", then save)
- go through the os installation process
- set your username and password
- finish the OS installation
- when the installation finishes, you should accept the prompt to reboot the machine.
- when the vm boots, log in with you username and password you set.

***network debugging***

- try the "vmware-netcfg" command on the host machine if you have trouble connecting. 
- you may need to change between bridged and host-only connections (
- check your network connection in the command line with 
- ```ping www.google.com```
- if you get bytes back you're connection is good.

***enable shared folders on the virtual machine***
- (right click the vm, go to settings, click the options tab, select "Always Enabled" for shared folders
- (select a path to the "shared" folder from LSU OneDrive, click save)
- I keep my path simple and put the files in a folder called 'shared'
- my path is /mnt/shared within the vm, if you use a different path, change it in all commands that use '/mnt/shared'


### Begin Build

These commands should all be executed in sequence from within the vmware CLI:

- ```sudo apt -y update```
- ```sudo apt -y upgrade```
- ```sudo apt -y install apache2 apache2-utils```
- ```sudo a2enmod ssl```
- ```sudo a2enmod rewrite```
- ```sudo systemctl restart apache2```
- ```sudo usermod -a -G www-data `whoami` ```
- ```sudo usermod -a -G `whoami` www-data```

- ```ls /mnt/shared```
- you should see the shared folders from LSU OneDrive. if you don't see the shared folder, run this command in the vmware cli:

### If bad mount point '/mnt/' no such file or directory:
- ```mkdir /mnt/``` 
- ```sudo vmhgfs-fuse .host:/ /mnt/ -o allow_other -o uid=1000```

## Start the build:
- execute in the vmware cli after shared folders are connected:
- ```sh /mnt/shared/shell-scripts/scratch_1.sh```
the above command runs a script containing the following:
>```
>#!/bin/bash
>sudo apt install -y lsb-release gnupg2 ca-certificates apt-transport-https software-properties-common
>sudo add-apt-repository ppa:ondrej/php
>sudo add-apt-repository ppa:ondrej/apache2
>sudo apt update
>``` 
________________________________________
# Install php and postgresql:
- ```sh /mnt/shared/shell-scripts/scratch_2.sh```

the above command runs the following script the :
>```
>#!/bin/bash
>sudo apt -y install php8.3 php8.3-cli php8.3-common php8.3-curl php8.3-dev php8.3-gd php8.3-imap php8.3-mbstring php8.3-opcache php8.3-xml php8.3-yaml php8.3-zip libapache2-mod-php8.3 php-pgsql php-redis php-xdebug unzip
>sudo a2enmod php8.3
>sudo systemctl restart apache2
># set default php to the version we have insalled:
>sudo update-alternatives --set php /usr/bin/php8.3
>#install Postgresql
>sudo apt install -y postgresql-common
>sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
>sudo apt install -y postgresql-15
># Upgrade:
>sudo apt-get upgrade
>```

Edit the postgresql.conf file starting at line 687

- ```sudo nano +687 /etc/postgresql/15/main/postgresql.conf```

change line 687 from 
>```
>#bytea_output = 'hex'
>```

change to
>```
>bytea_output = 'escape'
>```
- ```sudo systemctl restart postgresql```

________________________________________
# Setting Up PostgreSQL Database and User for Drupal 10:
***create up a drupal10 database and user***

- ```sudo -u postgres psql```

from within the postgres cli change to drupal10:
>```
>create database drupal10 encoding 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8' TEMPLATE template0;
>create user drupal with encrypted password 'drupal';
>```

***Grant privileges, Enable extension,Modify database setting***
>```
>\c drupal10
>GRANT ALL PRIVILEGES ON DATABASE drupal10 TO drupal;
>GRANT CREATE ON SCHEMA public TO drupal;
>CREATE EXTENSION pg_trgm;
>```

- ***Modify database setting***
>```
>ALTER DATABASE drupal10
>SET bytea_output = 'escape';
>\q
>```
- ```sudo systemctl restart postgresql```
- ***Editing pg_hba.conf for User Authentication in PostgreSQL***

```sudo cp /mnt/shared/configs/postgresql/pg_hba.conf /etc/postgresql/15/main/```
- Adds the following authentication settings for PostgreSQL users and databases on localhost. Note: Do not copy the configurations below into the pg_hba.conf file, as the indentations are incorrect.
>```
># Database administrative login by Unix domain socket
>local	  all		           all			                                  md5
>#local	  DATABASE		   USER			                                  METHOD
>```
________________________________________
# Install Composer

- ```sh /mnt/shared/shell-scripts/scratch_3.sh```

scratch_3.sh contents:
>```
>#!/bin/bash
>curl "https://getcomposer.org/installer" > composer-install.php
>chmod +x composer-install.php
>php composer-install.php
>sudo mv composer.phar /usr/local/bin/composer
>sudo mkdir /opt/drupal
>sudo chown www-data:www-data /opt/drupal
>sudo chmod 775 /opt/drupal
>sudo chown -R www-data:www-data /var/www/
>```

________________________________________
# Configure apache server settings:
- ```sudo cp /mnt/shared/configs/apache2/ports.conf /etc/apache2/ports.conf```
- ***Apache virtual host configuration***
  - ```sudo cp /mnt/shared/configs/apache2/000-default-v1.conf /etc/apache2/sites-enabled/000-default.conf```
  - ```sudo cp /mnt/shared/configs/apache2/000-default-v1.conf /etc/apache2/sites-available/000-default.conf```
- Copy command above edits the default virtual host configuration file located in /etc/apache2/sites-available/ and /etc/apache2/sites-enabled/.
>```
><VirtualHost *:80>
> ServerName localhost
> DocumentRoot "/opt/drupal"
> <Directory "/opt/drupal">
>   Options Indexes FollowSymLinks MultiViews
>   AllowOverride all
>   Require all granted
> </Directory>
> # Ensure some logging is in place.
> ErrorLog "/var/log/apache2/localhost_error.log"
> CustomLog "/var/log/apache2/localhost_access.log" combined
></VirtualHost>
>```
>
***Now We create a Drupal virtual host configuration file using***
- Copy over configuration from shared folder:

 - ```sudo cp /mnt/shared/configs/apache2/drupal-v1.conf /etc/apache2/sites-available/drupal.conf```
- Or paste following to /etc/apache2/sites-available/drupal.conf:
```sudo nano /etc/apache2/sites-available/drupal.conf```
>```
>Alias /drupal "/opt/drupal"
>DocumentRoot "/opt/drupal"
><Directory /opt/drupal>
>    AllowOverride All
>    Require all granted
></Directory>
>```
- ***Later in the installation steps, when we create an Islandora Starter Site project, we need to edit the root directory in the Apache configuration files as shown below, We will copy over 000-default.conf and drupal.conf with updated root directories***


#### Configuring and Securing Apache for Drupal Deployment
- ```sudo systemctl restart apache2``` 
- ```sudo a2ensite drupal```
- ```sudo a2enmod rewrite```
- ```sudo systemctl restart apache2```
- ```sudo chown -R www-data:www-data /opt/drupal```
- ```sudo chmod -R 755 /opt/drupal```


#### Add PDO extentions for postgresql and mysql:
- ```sh /mnt/shared/shell-scripts/PDO-extensions.sh```
The following shell script will execute the commands below:
>```
>sudo apt-get install php8.3-mysql
>sudo apt-get install php8.3-pgsql
>#For mariaDB
>sudo apt-get install php8.3-mysqli
>sudo add-apt-repository ppa:ondrej/php
>sudo add-apt-repository ppa:ondrej/apache2
>sudo apt update
>sudo systemctl restart apache2
>```

### Make sure postgresql and apache2 are both active:
- ```sudo systemctl restart postgresql apache2```
- ```sudo systemctl status postgresql apache2```

________________________________________
# install tomcat and cantaloupe
### Install JAVA 17.0.1 
- ***Create directory for Java installation:***
>```
>sudo mkdir /usr/lib/jvm
>cd /usr/lib/jvm
>```
- ***Download and extract the Java archive:***
>```
>sudo wget -O openjdk-17.0.1.tar.gz https://download.java.net/java/GA/jdk17.0.1/2a2082e5a09d4267845be086888add4f/12/GPL/openjdk-17.0.1_linux-x64_bin.tar.gz
>sudo tar -zxvf openjdk-17.0.1.tar.gz
>sudo mv jdk-17.0.1 java-17.0.1-openjdk-amd64
>```
- ***Set executable permissions and create a symbolic link:***
>```
>sudo chmod +x /usr/lib/jvm/java-17.0.1-openjdk-amd64/bin/java
>sudo ln -s /usr/lib/jvm/java-17.0.1-openjdk-amd64/bin/java /usr/bin/java
>```
- ***Verify the Java installation:***
>```
>java --version
>```
- ***Configure alternatives to manage different Java versions:***
>```
>sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-17.0.1-openjdk-amd64/bin/java 1
>update-alternatives --list java
>```
The output should include a line similar to: "/usr/lib/jvm/java-11-openjdk-amd64/bin/java"
note this path for later use as JAVA_HOME. it is the same as the path above without "/bin/java". "/usr/lib/jvm/java-117.0.1-openjdk-amd64"- ***Add Java_HOME in default environment variables***
- ***Add JAVA_HOME to Default Environment Variables:***
>```
>echo 'export JAVA_HOME=/usr/lib/jvm/java-17.0.1-openjdk-amd64' >> ~/.bashrc
>echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
>source ~/.bashrc
>```
________________________________________
### Install Tomcat:
- ***create tomcat user:***
- ```sudo addgroup tomcat```
- ```sudo adduser tomcat --ingroup tomcat --home /opt/tomcat --shell /usr/bin```
choose a password
ie: password: "tomcat"
press enter for all default user prompts
type y for yes

- ***install tomcat***
- find the tar.gz here: https://tomcat.apache.org/download-90.cgi
- ```sh /mnt/shared/shell-scripts/scratch_4.sh```

The following shell script will execute the commands below:
>```
>#!/bin/bash
>cd /opt
>#O not 0
>sudo mkdir tomcat
>sudo chown -R tomcat:tomcat /opt/tomcat
>sudo chmod 755 -r /opt/tomcat
>sudo wget -O tomcat.tar.gz https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.93/bin/apache-tomcat-9.0.93.tar.gz
>sudo tar -zxvf tomcat.tar.gz
>sudo mv /opt/apache-tomcat-9.0.93/* /opt/tomcat
>```
- Make sure to change the tomcat version in scrathc_4 in ```sudo mv /opt/apache-tomcat-9.0.89/* /opt/tomcat```

scratch_5.sh (if the tomcat tarball link is different you must change the path in the script or run the commands in the scratch_5 alt section):

- ```sh /mnt/shared/shell-scripts/scratch_5.sh```

- ***Copy environment variables that includes java home to tomcat/bin***
>```
>//Make sure version of openjdk java is correct in JAVA_HOME:
>sudo cp /mnt/shared/configs/tomcat_conf/setenv.sh /opt/tomcat/bin/
>sudo chmod 755 /opt/tomcat/bin/setenv.sh
>sudo cp /mnt/shared/configs/tomcat_conf/tomcat.service /etc/systemd/system/tomcat.service
>sudo chmod 755 /etc/systemd/system/tomcat.service
>sudo systemctl start tomcat
>sudo systemctl enable tomcat
>sudo systemctl status tomcat
>```
________________________________________
### Cantatloupe:
#### Install Cantaloupe 5.0.6
- ```sudo apt -y install libopenjp2-tools```
- ```sh /mnt/shared/shell-scripts/scratch_6.sh```

- scratch_6.sh will perform bellow tasks:
  - install and unzip cantaloupe 5.0.6
  - copy the configurations into cantaloupe_config
  - Copy cantaloupe service syetem directory
  - Enables Cantaloupe

>```
>sudo wget -O /opt/cantaloupe.zip https://github.com/cantaloupe-project/cantaloupe/releases/download/v5.0.6/cantaloupe-5.0.6.zip
>sudo unzip /opt/cantaloupe.zip
>sudo mkdir /opt/cantaloupe_config
>```
#### copy the configurations into cantaloupe_config
- ```sudo cp /mnt/hgfs/shared/cantaloupe.properties /opt/cantaloupe_config/cantaloupe.properties```
- ```sudo cp cantaloupe-5.0.6/delegates.rb.sample /opt/cantaloupe_config/delegates.rb```

#### Copy cantaloupe service syetem directory, check the version of your cantaloup in cantaloupe.service
>```
>sudo cp /mnt/shared/configs/cantaloupe/cantaloupe.service /etc/systemd/system/cantaloupe.service
>sudo chmod 755 /etc/systemd/system/cantaloupe.service
>```

#### Enable Cantaloupe
>```
>sudo systemctl enable cantaloupe
>sudo systemctl start cantaloupe
>sudo systemctl daemon-reload
>```

- ***Configure Cantaloupe URL(Important)***
>```
>sudo nano /opt/cantaloupe_config/cantaloupe.properties
>#set this in properties: base_uri = http://127.0.0.1:8182/iiif/2
>```
- ***Restart and Check the status***
>```
>sudo systemctl restart cantaloupe
>sudo systemctl status cantaloupe
>```

### Installing fedora
#### stop tomcat and create fcrepo directy
- ```sudo systemctl stop tomcat```
- ```sudo mkdir -p /mnt/fcrepo/data/objects```
- ```sudo cp -R /mnt/shared/configs/fedora_configs/config /mnt/fcrepo/```
- ```sudo chown -R tomcat:tomcat /mnt/fcrepo```
- ```sudo chmod -R 755 /mnt/fcrepo```

#### Create fcrepo database, user, password in postgresql or maridb:
- ```sudo -u postgres psql```
>```
>create database fcrepo encoding 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8' TEMPLATE template0;
>create user fedora with encrypted password 'fedora';
>\c fcrepo
>grant all privileges on database fcrepo to fedora;
>GRANT CREATE ON SCHEMA public TO fedora;
>\q
>```

### Adding the Fedora Variables to JAVA_OPTS, change setenv:
- ```sudo nano /opt/tomcat/bin/setenv.sh```

- uncomment line 5, comment line 4 (CTL-c) shows line number

- ```sudo chown tomcat:tomcat /opt/tomcat/bin/setenv.sh```

### Edit and Ensuring Tomcat Users Are In Place
- ```cp /mnt/shared/configs/fedora_configs/tomcat-and-syn-for-fedora/tomcat-users.xml /opt/tomcat/conf```
- tomcat-users permission:
>```
>sudo chmod 600 /opt/tomcat/conf/tomcat-users.xml
>sudo chown tomcat:tomcat /opt/tomcat/conf/tomcat-users.xml
>```


### download fedora Latest Release:
- **NOTE:** You may want to check visit [fcrepo repository](https://github.com/fcrepo/fcrepo/releases) to choose the latest version and ajust the commands below if needed
- ```sh /mnt/shared/shell-scripts/fedora-dl.sh```
- The following shell script will execute the commands below to download fedora war file and will place it to catalina webapp directory:
>```
>#!/bin/bash
>cd /opt
>sudo wget -O fcrepo.war https://github.com/fcrepo/fcrepo/releases/download/fcrepo-6.5.0/fcrepo-webapp-6.5.0.war
>sudo mv fcrepo.war /opt/tomcat/webapps
>sudo chown tomcat:tomcat /opt/tomcat/webapps/fcrepo.war
>```

### Enable fedora and Start Fedora:
- **Start Tomcat server:**
  - ```/opt/tomcat/bin/startup.sh```

- **Restart tomcat:**
  - ```sudo systemctl start tomcat```

### Navigate to Fedora endpoint:
- Once tomcat starts up, Fedora REST API should be available at **http://localhost:8080/fcrepo/rest**.
- The username is **fedoraAdmin** and we defined the password before as FEDORA_ADMIN_PASSWORD (We set: "islandora").
________________________________________
# Syn:
### Download syn:
check here for link [Islandora Syn](https://github.com/Islandora/Syn/releases/) to check for latest version:
- run the command:
- ```sh /mnt/shared/shell-scripts/syn-dl.sh```
>```
>#!/bin/bash
>sudo wget -P /opt/tomcat/lib https://github.com/Islandora/Syn/releases/download/v1.1.1/islandora-syn-1.1.1-all.jar
>sudo chown -R tomcat:tomcat /opt/tomcat/lib
>sudo chmod -R 640 /opt/tomcat/lib
>```

### Generating an SSL Key for Syn and Placing the Syn Settings:
- ```sudo sh /mnt/shared/shell-scripts/syn-config.sh```
- The following shell script will execute the commands below:

>```
>#!/bin/bash
>sudo mkdir /opt/keys
>sudo openssl genrsa -out "/opt/keys/syn_private.key" 2048
>sudo openssl rsa -pubout -in "/opt/keys/syn_private.key" -out "/opt/keys/syn_public.key"
>sudo chown www-data:www-data /opt/keys/syn*
>sudo mkdir /opt/syn
>sudo cp /mnt/shared/configs/fedora_configs/tomcat-and-syn-for-fedora/syn-settings.xml /mnt/fcrepo/config/
>sudo chown tomcat:tomcat /mnt/fcrepo/config/syn-settings.xml
>sudo chmod 600 /mnt/fcrepo/config/syn-settings.xml
>```

### Adding the Syn Valve to Tomcat | Enable the Syn Valve for all of Tomcat:
- Add Syn path to tomcat context.xml:
```sh
sudo cp /mnt/shared/configs/fedora_configs/tomcat-and-syn-for-fedora/context.xml /opt/tomcat/conf
sudo chmod 644 /opt/tomcat/conf/context.xml
sudo chown tomcat:tomcat /opt/tomcat/conf/context.xml
```
- ```sudo systemctl restart tomcat```


### Redhat logging:
- alter your $JAVA_OPTS like above to include:
  - **Before:** export JAVA_OPTS="-Djava.awt.headless=true -Dfcrepo.config.file=/mnt/fcrepo/config/fcrepo.properties -DconnectionTimeout=-1 -server -Xmx1500m -Xms1000m"
  - **After:** export JAVA_OPTS="-Djava.awt.headless=true -Dfcrepo.config.file=/mnt/fcrepo/config/fcrepo.properties -Dlogback.configurationFile=/mnt/fcrepo/config/fcrepo-logback.xml -DconnectionTimeout=-1 -server -Xmx1500m -Xms1000m"
 
- ```sudo nano /opt/tomcat/bin/setenv.sh```
- Comment line 5 and uncomment line 6

________________________________________
# installing blazegraph
### Creating a Working Space for Blazegraph and install Blazegraph:
- ```sh /mnt/shared/shell-scripts/blazegraph-dl.sh```
>```
>sudo mkdir -p /opt/blazegraph/data
>sudo mkdir /opt/blazegraph/conf
>sudo chown -R tomcat:tomcat /opt/blazegraph
>cd /opt
>sudo wget -O blazegraph.war https://repo1.maven.org/maven2/com/blazegraph/bigdata-war/2.1.5/bigdata-war-2.1.5.war
>sudo mv blazegraph.war /opt/tomcat/webapps
>sudo chown tomcat:tomcat /opt/tomcat/webapps/blazegraph.war
>```
### Configuring Logging and Adding Blazegraph Configurations:
- ```sh /mnt/shared/shell-scripts/blazegraph_conf.sh```

The following shell script will execute the commands below:
>```
>#!/bin/bash
>#Configuring Logging
>sudo cp /mnt/shared/log4j.properties /opt/blazegraph/conf/
>sudo chown tomcat:tomcat /opt/blazegraph/conf/log4j.properties
>sudo chmod 644 /opt/blazegraph/conf/log4j.properties
>#Adding a Blazegraph Configuration
>sudo cp /mnt/shared/RWStore.properties /opt/blazegraph/conf
>sudo chown tomcat:tomcat /opt/blazegraph/conf/RWStore.properties
>sudo chmod 644 /opt/blazegraph/conf/RWStore.properties
>sudo cp /mnt/shared/blazegraph.properties /opt/blazegraph/conf
>sudo chown tomcat:tomcat /opt/blazegraph/conf/blazegraph.properties
>sudo chmod 644 /opt/blazegraph/conf/blazegraph.properties
>sudo cp /mnt/shared/inference.nt /opt/blazegraph/conf
>sudo chown tomcat:tomcat /opt/blazegraph/conf/inference.nt
>sudo chmod 644 /opt/blazegraph/conf/inference.nt
>sudo chown -R tomcat:tomcat /opt/blazegraph/conf
>sudo chmod -R 644 /opt/blazegraph/conf
>```

### Specifying the RWStore.properties in JAVA_OPTS:
- ```sudo nano /opt/tomcat/bin/setenv.sh```
Comment line 6 and uncomment line 7:

- **Before:** export JAVA_OPTS="-Djava.awt.headless=true -Dfcrepo.config.file=/opt/fcrepo/config/fcrepo.properties -DconnectionTimeout=-1 -server -Xmx1500m -Xms1000m"
- **After:** export JAVA_OPTS="-Djava.awt.headless=true -Dfcrepo.config.file=/opt/fcrepo/config/fcrepo.properties -Dlogback.configurationFile=/opt/fcrepo/config/fcrepo-logback.xml -DconnectionTimeout=-1 Dcom.bigdata.rdf.sail.webapp.ConfigParams.propertyFile=/opt/blazegraph/conf/RWStore.properties -Dlog4j.configuration=file:/opt/blazegraph/conf/log4j.properties -server -Xmx1500m -Xms1000m"

- Comment line 6 and uncomment line 7

- ```sudo systemctl restart tomcat```
### Installing Blazegraph Namespaces and Inference:
- ```sudo curl -X POST -H "Content-Type: text/plain" --data-binary @/opt/blazegraph/conf/blazegraph.properties http://localhost:8080/blazegraph/namespace```

If this worked correctly, Blazegraph should respond with **"CREATED: islandora"** to let us know it created the islandora namespace.

- ```sudo curl -X POST -H "Content-Type: text/plain" --data-binary @/opt/blazegraph/conf/inference.nt http://localhost:8080/blazegraph/namespace/islandora/sparql```

If this worked correctly, Blazegraph should respond with some XML letting us know it added the 2 entries from inference.nt to the namespace.
________________________________________
# installing solr
#### Check JAVA_HOME:
- ```sudo nano ~/.bashrc```
>```
>export JAVA_HOME=/usr/lib/jvm/java-17.0.1-openjdk-amd64
>export PATH=$JAVA_HOME/bin:$PATH
>```
- ```source ~/.bashrc```

#### download 9.x solr:
```sh /mnt/shared/shell-scripts/solr-dl.sh```
>```
>cd /opt
>sudo wget https://www.apache.org/dyn/closer.lua/solr/solr/9.6.0/solr-9.6.0.tgz?action=download
>sudo mv solr-9.6.0.tgz?action=download solr-9.6.0.tgz
>sudo tar xzf solr-9.6.0.tgz solr-9.6.0/bin/install_solr_service.sh --strip-components=2
>```
#### Install Solr:
run following as root to extract and install solr:
- ```sudo bash ./install_solr_service.sh solr-9.6.0.tgz -i /opt -d /var/solr -u solr -s solr -p 8983```

##### Runnig the above command will do the following:
- extracted solr-9.6.0 to /opt
- symlink /opt.solr -> /opt/solr-9.6.0
- installed /etc/init.d/solr script 
- installed /etc/default/solr.in.sh
- service solr installed
##### to customize solr startup configuration go to this directory /etc/default/solr.in.sh:
- SOLR_PID_DIR="/var/solr"
- SOLR_HOME="/var/solr/data"
- LOG4J_PROPS="/var/solr/log4j2.xml"
- SOLR_LOGS_DIR="/var/solr/logs"
- SOLR_PORT="8983"
  
#### Adjust Kernel Parameters:

- ```sudo su```
- ```sudo echo "fs.file-max = 65535" >> /etc/sysctl.conf```
- ```sudo sysctl -p```

#### make sure solr is running:
- ```sudo systemctl status solr```
- **If it was not running:**
  - ```cd /opt/solr-9.6.0```
  - ```bin/solr start```
- ```sudo systemctl status solr```

#### Create Solr Core
- ```sudo mkdir -p /var/solr/data/islandora8```
- ```sudo cp -r /mnt/shared/configs/solr_9.x/conf /var/solr/data/islandora8```
- ```sudo chown -R solr:solr /var/solr```
- ```cd /opt/solr-9.6.0```
- ```sudo -u solr bin/solr create -c islandora8 -p 8983```
***We will configure index via gui after site installed***
________________________________________
# ActiveMQ/Alpaca:
## 1. ActiveMQ:
### Create ActiveMQ User:
- ```sudo useradd -m -d /opt/activemq -s /bin/false activemq```

### Download and un-archive ActiveMQ:
>```
>sudo chmod 775 /opt/activemq 
>cd /opt/activemq
>sudo wget https://repository.apache.org/content/repositories/snapshots/org/apache/activemq/apache-activemq/6.2.0-SNAPSHOT/apache-activemq-6.2.0-20240816.205844-15-bin.tar.gz
>sudo tar zxvf apache-activemq-6.2.0-20240816.205844-15-bin.tar.gz
>sudo mv apache-activemq-6.2.0-SNAPSHOT/* .
>sudo rm -rf apache-activemq-6.2.0-SNAPSHOT apache-activemq-6.2.0-20240816.205844-15-bin.tar.gz
>```

#### Set permissions to ActiveMQ directory:
>```
>sudo chown -R activemq:activemq /opt/activemq
>sudo chmod -R 775 /opt/activemq 
>sudo chmod -R 775 /opt/activemq/bin/activemq
>```

#### Set Up Environment Variables, Add the following to /etc/default/activemq:
- Add activemq user to activemq environment file:
>```
>#copy over activemq environment variables
>sudo mkdir /etc/default/activemq
>sudo cp /mnt/shared/configs/activemq/setenv /opt/activemq/bin/setenv
>sudo cp /mnt/shared/configs/activemq/setenv /etc/default/activemq
>```

##### Set correct permissions:
>```
>sudo chmod -R 755 /etc/default/activemq
>sudo nano /etc/default/activemq
>```

#### Create a symlink to the init script and enable the service:
>```
>sudo ln -snf /opt/activemq/bin/activemq /etc/init.d/activemq 
>sudo update-rc.d activemq defaults
>```
#### correct permissions to activemq and check symlink:
- ```ls -l /etc/init.d/activemq```
- ```sudo systemctl daemon-reload```

#### Set Up Service:
- ```sudo cp /mnt/shared/configs/activemq/activemq.service /etc/systemd/system/activemq.service```
- reload systemd to recognize the new service ```sudo systemctl daemon-reload```
- activemq.service contains:
>```
>[Unit]
>Description=Apache ActiveMQ
>After=network.target
>
>[Service]
>Type=forking
>User=activemq
>Group=activemq
>ExecStart=/opt/activemq/bin/activemq start
>ExecStop=/opt/activemq/bin/activemq stop
>Restart=always
>
>[Install]
>WantedBy=multi-user.target
>```

#### Enable an start Service:
>```
># Start with system control
>sudo systemctl enable activemq
>sudo systemctl start activemq
>sudo systemctl status activemq
>
>#start from activemq directory:
>/opt/activemq/bin/activemq start
>```


#### Ckeck started on the port:
- you should see activemq is running on port 61616 with
  - ```sudo lsof -i :61616```
- Or:
  - ```netstat -a | grep 61616```

#### ActiveMQ ConfigurationL(Important)
- ActiveMQ expected to be listening for STOMP messages at a tcp url. If not the default tcp://127.0.0.1:61613, this will have to be set:
- Copy over these two configurations for setup webconsole and Stopmp ports:
>```
># activemq main configurations:
>sudo cp /mnt/shared/configs/activemq/activemq.xml /opt/activemq/conf
>
># for web console accessibility
>sudo cp /mnt/shared/configs/activemq/jetty.xml /opt/activemq/conf
>```
## 2. Crayfish Microservices:
#### Clone Isandora Crayfish repository:
```sh
sudo mkdir /opt/crayfish
cd /opt/crayfish
sudo -u www-data git clone https://github.com/Islandora/Crayfish.git /opt/crayfish
```

#### Install Required Services on VM:
- Bellow shell scripts will install required services for Crayfish Microservices to perform their tasks:
- ```sudo sh /mnt/shared/shell-scripts/crayfish-requriments.sh```

#### Configure Virtual Host for Crayfits and Crayfish microservices:
- ```sudo sh /mnt/shared/shell-scripts/crayfish-virtual-host.sh```
- Above command will perform bellow tasks:
    - Copy over apache configuration for all microservices on port `8000`.
    - Enable apache ***virtual host*** for microservices.
    - Update ***Apache Ports*** to listen to port `8000` and Restart apache service.
 
#### Move Crayfish configuration files over:
- ```sudo sh /mnt/shared/shell-scripts/crayfish-configs.sh```

#### Configure Logging:
- ```sudo sh /mnt/shared/shell-scripts/crayfish-logging.sh```
- Above command will create directory on `/var` and set correct permissions so that microservices can write the log files for future debugging.

#### Authentication with fedora repository:
- Authentication is ***not set***, and in configurations it's set to disable
- We should come back to handle authentication between Fedora and Micro Services.

#### Install Crayfits:
- ```sudo sh /mnt/shared/shell-scripts/crayfits_install.sh```
- Above command will perform these tasks.
    - Create directory for Fits.
    - Download Fits files:
    - Next, adds two lines to set Fits home directory to catalina properties.

#### Install Crayfish Commons:
- ```sudo sh /mnt/shared/shell-scripts/crayfish-commons.sh```

#### Install Crayfish microservices:
- Run bellow command to install Crayfish Microservices:
- ```sudo sh /mnt/shared/shell-scripts/crayfish-install.sh```
## 3. Alpaca:
#### Alpaca importance in islandora ecosystem:
- Alpaca integrates and manages various microservices in an Islandora installation, handling content indexing, derivative generation, message routing from Drupal, service integration with repositories and endpoints, and configuration management for seamless system functionality.

- Java middleware that handle communication between various components of Islandora.

- In more detail, Alpaca will connect to the ActiveMQ broker, handle HTTP requests, index content in Fedora and Triplestore, and generate derivatives using FITS, Homarus, Houdini, and OCR services based on the queues and URLs specified in the configuration file.
#### Download alpaca.jar:
- Make a directory for Alpaca and download the latest version of Alpaca from the Maven repository. E.g.
>```
>sudo mkdir /opt/alpaca
>sudo chmod -R 775 /opt/alpaca
>cd /opt/alpaca
>curl -L https://repo1.maven.org/maven2/ca/islandora/alpaca/islandora-alpaca-app/2.2.0/islandora-alpaca-app-2.2.0-all.jar -o alpaca.jar
>```
#### Copy Alpaca Config files:
- Alpaca is made up of several microservices, each of these can be configured, enabled or disabled individually with an alpaca properties.
    - bellow command will copy over alpaca properties.
    - ```sudo cp /mnt/shared/configs/alpaca/alpaca.properties /opt/alpaca/```
- Copy over alpaca services to systemd:
    - ```sudo cp /mnt/shared/configs/alpaca/alpaca.service /etc/systemd/system```
#### Run Alpaca: 
1. Run from alpaca directory, for testing purpose, And ```CTL+C``` to cancel running it.
```sh
cd /opt/alpaca
java -Dislandora.alpaca.log=DEBUG -jar alpaca.jar -c alpaca.properties
```
2. Run with systemd: ```sudo systemctl start alpaca```

#### Notes:
##### 1. Alpaca integration with Workbench:
- As of now Alpaca integrates with workbench on indexing new content to fedora resource and triplestore
- It wont integrate with Workbench on handeling Derivitive when media created with Workbench, For now to do this we may need to:
  - Index media to fedora manually under content/media and start action to index media to fedora and triplestore
  - And we need to start action for create derivitives manualy under Content page
##### 2. Configuration:
- If we are installing everything on the same server, the provided example properties should be fine as-is. Simply rename the file to alpaca.properties and run the command mentioned above.
- If Alpaca is running on a different machine, we will just need to update the URLs in the configuration file to point to the correct host for the various services.
##### 3. Alpaca Activity:
- We won't see much activity from Alpaca until our ActiveMQ is populated with messages from Drupal, such as requests to index content or generate derivatives.

### Notes:
1. **Alpaca integration with Workbench:**
    - As of now Alpaca integrates with workbench on indexing new content to fedora resource and triplestore
    - It wont integrate with Workbench on handeling Derivitive when media created with Workbench, For now to do this we may need to:
      - Index media to fedora manually under content/media and start action to index media to fedora and triplestore
      - And we need to start action for create derivitives manualy under Content page
2. **Configuration:**
    - If we are installing everything on the same server, the provided example properties should be fine as-is. Simply rename the file to alpaca.properties and run the command mentioned above.
    - If Alpaca is running on a different machine, we will just need to update the URLs in the configuration file to point to the correct host for the various services.
3. **Alpaca Activity:**
    - We won't see much activity from Alpaca until our ActiveMQ is populated with messages from Drupal, such as requests to index content or generate derivatives.
________________________________________
# Download and Scaffold Drupal, Create a project using the Islandora Starter Site:
#### install php-intl 8.3:
```sudo apt install -y php8.3-intl```

#### create islandora starter site project

- ```cd /opt/drupal```
- ```sudo -u www-data composer create-project islandora/islandora-starter-site:1.8.0```
- ```cd /opt/drupal/islandora-starter-site```

#### Install drush using composer at islandora-starter-site
- ```sudo chown -R www-data:www-data /opt/drupal/islandora-starter-site```
- ```sudo chmod 775 -R /opt/drupal/islandora-starter-site```
- ```sudo -u www-data composer require drush/drush```
- ```sudo ln -s /opt/drupal/islandora-starter-site/vendor/bin/drush /usr/local/bin/drush```
- ```ls -lart /usr/local/bin/drush```

#### Configure Settings.php and add Flysystem's fedora and trusted host:
1. Copy the settings.php for drupal in 
```sudo cp /mnt/shared/configs/settings.php /opt/drupal/islandora-starter-site/web/sites/default/```
2. edit trusted host patterns and add your ip address.
```sudo nano web/sites/default/settings.php```
>```
>$settings['trusted_host_patterns'] = [
>  'localhost',
>  'YOUR_IP_ADDRESS',
>];
>
>$settings['flysystem'] = [
>  'fedora' => [
>    'driver' => 'fedora',
>    'config' => [
>      'root' => 'http://127.0.0.1:8080/fcrepo/rest/',
>    ],
>  ],
>];
>```

#### Re-configure Apache root directories:
#### 1. Re-configure drupal.conf:
- ```sudo cp /mnt/shared/configs/apache2/drupal.conf /etc/apache2/sites-enabled/drupal.conf```

- **Bellow is the lines that Changed in drupal.conf Apache configuration:**
>```
>Alias /drupal "/opt/drupal/islandora-starter-site/web"
>DocumentRoot "/opt/drupal/islandora-starter-site/web"
><Directory /opt/drupal/islandora-starter-site>
>```

#### 2. Re-configure 000-default.conf:
- ```sudo cp /mnt/shared/configs/apache2/000-default.conf /etc/apache2/sites-enabled/000-default.conf```
- ```sudo cp /mnt/shared/configs/apache2/000-default.conf /etc/apache2/sites-available/000-default.conf```

- **Bellow is the lines that Changed in 000-default.conf Apache configuration:**
>```
> DocumentRoot "/opt/drupal/islandora-starter-site/web"
> <Directory "/opt/drupal/islandora-starter-site/web">
>```

#### Then restart apache:
- ```sudo systemctl restart apache2```

#### change permission on the web directory:
- ```sudo chown -R www-data:www-data /opt/drupal/islandora-starter-site/web```
- ```sudo chmod -R 775 /opt/drupal/islandora-starter-site/web```

#### Again, make sure you have already done followings:
- You should have granted all privileges to the user Drupal when created the table and databases before site install so that these are all permissions on user to create tables on database.
- You should have installed PDO extention before site install.
________________________________________
# Install the site using composer or drush:
- **1. install using Composer:**
  - ```sudo -u www-data composer exec -- drush site:install --existing-config```
 
- **2. Install with Drush:**
  - ```sudo -u www-data drush site-install --existing-config --db-url="pgsql://drupal:drupal@127.0.0.1:5432/drupal10"```

#### Change default username and password:
- ```sudo drush upwd admin admin```
________________________________________
# Add a user to the fedoraadmin role:
for example, giving the default admin user the role using one the steps bellow:

#### 1. Using Composer:
- ```cd /opt/drupal/islandora-starter-site```
- ```sudo -u www-data composer exec -- drush user:role:add fedoraadmin admin```
 
#### 2. OR Using Drush:
- ```cd /opt/drupal/islandora-starter-site```
- ```sudo -u www-data drush -y urol "fedoraadmin" admin```
________________________________________
# Configure the locations of external services:
Some, we already configured in prerequsits, but we will make sure all the configurations are in place.
#### Check following configurations before moving forward:
- check if your services like cantaloupe, apache, tomcat, databases are available and working
    - ```sudo systemctl status cantaloupe apache2 tomcat postgresql```
    - then hit `q` to exit
- check if you have already configured the cantaloup IIIF base URL to http://127.0.0.1:8182/iiif/2
- check if you have already configured activemq.xml in name="stomp" uri="stomp://127.0.0.1:61613"

#### solr search_api installation and fiele size:
- ```sudo -u www-data composer require drupal/search_api_solr```

### Configurations:
#### 1. Configure Cantaloupe OpenSeaDragon:
- In GUI:
- Navigate to ```/admin/config/media/openseadragon```

- set location of the cantaloupe iiif endpoint to ```http://127.0.0.1:8182/iiif/2```

- select IIIF Manifest from dropdown

- save

#### Configure Cantaloupe for Islandora IIIF:
- /admin/config/islandora/iiif
- set location of the cantaloupe: ```http://127.0.0.1:8182/iiif/2```

#### Configure ActiveMQ, islandora message broker sertting url:
- /admin/config/islandora/core
- set brocker URL to tcp://127.0.0.1:61613 

- **If activeMQ was not active check activemq.service:**
  - sudo netstat -tuln | grep LISTEN
  - Check if 61613 is active and being listed to
 
#### Configure solr:
- **Check for bellow configuration:**
  - Check solr is availabe at port 8983: ``````sudo lsof -i :8983``````
  - Check solr is running if not run: sudo /opt/solr/bin/start 
  - Then restart: sudo systemctl restart solr
  - Check if your solr core is installed!

- **In GUI**: Navigate to `admin/config/search/search-api` edit the existing server or create one:
  - backend: Solr
  - Solr Connector: Standard
  - Solr core: islandora8

### syn/jwt configuration:
- Check if syn_private and syn_private keys are available at /opt/keys/
- First, Navigate to `/admin/config/system/keys/Edit`
  - key type: JWT RSA KEy
  - JWT Algorithm: RSAASA-PKCXS1-v1_5 Using SHA-256(RS256)
  - Key Provider: file
  - File location: /opt/keys/syn_private.key
  - Save
   
 - If you created new key, then, Navigate to /admin/config/system/jwt
    - Select the key you justy created
    - Save configuration

#### Select default Download location Flysystem:
visit /admin/config/media/file-system to select the flysystem:fedora
________________________________________
# Run the migrations command and Enabling EVA Views:
run the migration tagged with islandora  to populate some taxonomies.

#### Run the migrations taged with islandora:
- ```cd /opt/drupal/islandora-starter-site```
- ```sudo -u www-data composer exec -- drush migrate:import --userid=1 --tag=islandora```

#### Enabling EVA Views:
- ```drush -y views:enable display_media```
________________________________________
# instrall group modules and dependencies:
- ```cd /opt/drupal/islandora-starter-site```
- ```sudo -u www-data composer require digitalutsc/islandora_group```
- ```sudo -u www-data composer require 'drupal/rules:^3.0@alpha'```
- ```drush en -y islandora_group gnode rules```
#### Rebuild Cache:
- ```drush cr```
________________________________________

# Extra Drupal Configuratin
- a. Extra Configuration on Drupal For Alpaca
- b. Extra Configuration on Drupal For Groups
    - Anonymous user role:
        1. Go to: /admin/group/types/manage/admin/roles
	2. Click "Add group role"
	3. Name the role "Anonymous"
        4. Select "Outsider" as the **Scope**
	5. After the role is created select "Edit permissions"
	6. click the checkbox for the following permissions:
	    - Group General: "View published group"
            - Group media (Audio): "Entity: View any media item enttities"
            - Group media (Audio): "Relationship: View any entity relations"
            - Group media (Document): "Entity: View any media item enttities"
            - Group media (Document): "Relationship: View any entity relations"
            - Group media (Extracted Text): "Entity: View any media item enttities"
            - Group media (Extracted Text): "Relationship: View any entity relations"
            - Group media (FITS Technical metadata): "Entity: View any media item enttities"
            - Group media (FITS Technical metadata): "Relationship: View any entity relations"
            - Group media (File): "Entity: View any media item enttities"
            - Group media (File): "Relationship: View any entity relations"
            - Group media (Image): "Entity: View any media item enttities"
            - Group media (Image): "Relationship: View any entity relations"
            - Group media (Remote Video): "Entity: View any media item enttities"
            - Group media (Remote Video): "Relationship: View any entity relations"
            - Group media (Video): "Entity: View any media item enttities"
            - Group media (Video): "Relationship: View any entity relations"
            - Group media type: "Relationship: View any entity relations"
            - Group node (Repository Item): "Entity: View any content item entities"
            - Group node (Repository Item): "Relationship: View any entity relations"
- c. Extra Configuration for Manually assign Derivatives to Groups in Drupal
- c. Configure apache2 php.ini

## a. Extra Configuration on Drupal For Alpaca:
#### Step 1: Configuring Text Extraction Derivative Actions
1. Go to **Configuration > System > Actions**.
2. Create a new action called `Get OCR from Image`
    - **Machine Name:** Rename the machine name to `get_ocr_from_pdf`.
    - **Label:** Change the label to `Extract Text from PDF`.
3. Configure the existing action for text extraction called `Extract Text from Image or PDF`:
    - **Edit the Action Label:** Change the label to `Extract Text from Image`.
    - **Additional Arguments:** Add the following arguments: `--psm 6 -l eng --dpi 300 -c tessedit_create_txt=1`. These arguments are used to generate text from images using Tesseract.

### Step2. Configuring Actions:
#### Step 1: Create Action for OCR From image and PDF:
1. Go to **Configuration > System > Actions**.
2. For each Action bellow, select **Fedora** as the file system.
3. Bellow is the list of actions that storage location i needed to be configured:
  - **Audio** - Generate a service file from an original file.
  - **Digital Document** - Generate a thumbnail from an original file.
  - **Extract Text from Image**.
  - **Extract Text from PDF**.
  - **FITS** - Generate technical metadata derivative.
  - **Image** - Generate a service file from an original file.
  - **Image** - Generate a thumbnail from an original file.
  - **Video** - Generate a service file from an original file.
  - **Video** - Generate a thumbnail at 0:00:03.
  - **Video** - Generate a thumbnail from an original file.

#### Notes:
- You can manually add additional arguments to any of these actions if needed. For example:
    - Use **FFmpeg** to change file types.
    - Use **Tesseract** to generate text from media files.
___________________________________________________________________________________________________________________________
### 2. Configuring Media Types:
#### Step 1: Edit File System Location for Media Types
1. Go to **Administration > Structure > Media Types**.
2. For each media type (e.g., Image, Video, Audio):
    - Go to **Manage Fields**.
    - Locate the field that stores the file (the field that `file_type` named `File` or similar).
    - Click **Edit** next to that field.
    - Under **File System**, select **Fedora**.
    - Path: `<MediaType>/Manage fields/<TheOne_fieldType_IS_file>/File System: Fedora`

#### Step 2: Configure the "Media Of" Field
1. For each media type:
    - Go to **Manage Fields**.
    - Locate the `field_media_of` field.
    - Click **Edit** next to that field.
    - Under **Content Type**, select `Repository Item`.
    - Path: `<MediaType>/Manage fields/Media of/Content type: Repository Item`
___________________________________________________________________________________________________________________________
### 3. Configuring Contexts:
#### Step 1: Configuring Image Derivatives for Text Extraction
1. Go to **Administration > Structure > Context**.
2. Locate the context named **Image Derivatives** and click **Edit**.
3. Under **Reactions > Derivatives > Actions**, While Holding `CTL` botton, add the action **Extract Text from Image**.
    - This action should be configured as described in section 1, including the Tesseract arguments.
4. Explanation:
    - After creating an `Image` content model, you can attach both `Image` files (e.g., JPG, PNG) and `File` types (e.g., TIFF, JP2) to the content to be processed for text extraction.
    - Note: A thumbnail generation action should already be assigned.

#### Step 2: Configuring PDF Derivatives for Text Extraction
1. Go to **Administration > Structure > Context**.
2. Locate the context named **PDF Derivatives** and click **Edit**.
3. Under **Reactions > Derivatives > Actions**, While Holding `CTL` botton, add the action **Extract Text from PDF**.
    - This action should be configured as described in section 1, using `pdftotext` for PDF processing.
4. Explanation:
    - After creating a `Digital Document` content model, you can attach `Document` files (PDFs) to the content to be processed for text extraction.
    - Note: A thumbnail generation action should already be assigned, such as `Digital Document - Generate thumbnail from Original file`.

#### Step 3: Configuring Video Derivatives for Audio Extraction
1. Go to **Administration > Structure > Context**.
2. Locate the context named **Video Derivatives** and click **Edit**.
3. Under **Reactions > Derivatives > Actions**, add the action **Audio - Generate a service file from an original file**.
4. Explanation:
    - The context should already have a thumbnail generation action assigned, such as `Video - Generate thumbnail from Original file`.
---

## b. Extra Configuration on Drupal For Groups:
#### group type:
- Navigate to groups -> create a group type

#### Groups role and group role permissions:
- **Create specific roles:**
  - Navigate to Groups>Grope Type> edit group role of created Group Type > 
  - For administratiopn access we create roles for admin, and ensure each role has the appropriate admin permissions:
    -  Admin individual with administration roles
    -  Admin Outsider
    -  Admin Insider

  - You can also create different roles for members, content creators, or other specific roles, and assign these roles to specific users.

- **Assign role to the user**:
  - In Drupal, navigate to Admin > People to manage user roles:

    - Assign the administrator role to your user.

    - You can also assign users as content creators for specific group types. This way, they will only have access to the group types and groups they are assigned to, and will not have access to other group types or groups within those types.

#### Assign islandora access To the group type we created:
- Navigate to ```configuration -> access controll -> select islandora_access for <GroupTypeName>```

#### Create Group:
- Mavigate to Groups> Create Groups

#### Create field access terms for Repository Item Content type:
- Navigate to ```structure -> content types -> repository item -> manage fields -> create a access terms (name = access_terms) -> type is Reference -> Reference type: Taxonomy term, Vocabulary: Islandora Access```

#### Create field access terms for each Media types :
- Navigate to ```structure -> mediatypes -> edit one of the media types -> edit -> manage fields -> create a field -> create a access terms field (name = access_terms) -> type is Reference -> Reference type = Islandora Access```
  - Example: We craete field access terms for audio and machine name in list of fields is field_access_terms

- For each media type, we need to have field access terms. After creating field_access_terms for one media type (ex: audio) this can be re-used for other media types.
  - Example: After creating field_access_terms for one of the 

#### Select islandora access for each nodes and media:
- Navigate to ```configuration -> access controll -> islandora access```

- Select islandora_access for the repository items content type and all media types.
- Select islandora_access for the each media types.

#### set available content in group type:
- navigate to groups>group type> set avaialble content
- install plugin for Repository item content types:
  - Change cardinality to 1
- Install plugin for each Group media types:
  - add cardinality to 1
  - Check Enable Meida tracking

#### Fix the destination for each media type (Important for media ingestion for each media types):
- Navigate ```Structure>Media types```
 
- For each media type, edit the field where the type is file and set the Upload destination to Public files (for fedora-less system)
   - Example: for audio: field_media_audio_file
   - Image media type's field type is **Image** not **file**
---
## c. Manually Assigning Derivatives to Groups in Drupal: 
- In a typical Islandora/Drupal setup, when you create media, derivatives like thumbnails, service files, are automatically generated using the Alpaca microservices. While the derivatives are created automatically, Drupal does not always assign these derivatives to the same group or access control settings as the original media by default
### 1. Create a Separate Action for Each Group:
- For each group, you’ll need to create a separate action to streamline the process of assigning media to specific groups.

### 2. Create an Action to Assign Media to a Specific Group:
- Navigate to Configuration > System > Actions.
- Under Create an advanced action, create a new action called "Assign Media to Groups."
- Edit the action:
    - Label: Set the label to something descriptive, such as "Assign media to LSU."
    - Machine Name: Adjust the machine name accordingly, for example, assign_media_to_lsu.
    - Add to Group: Enter the name of the group to which the media should be assigned.
    - Save the action.

### 3. Navigate to the Media Library and Identify Derivatives:
- In your Drupal dashboard, go to Content > Media. This will show a list of all media files, including the original files and their derivatives (e.g., thumbnails).


### 4. Edit the Derivative File:
- Check the box next to the derivative media file (such as the thumbnail) that you want to assign to a group.
- From the Actions drop-down menu, select the action we created to assign media to a group.

### 5. Assign the Action:
- Choose the action you created (e.g., "Assign media to LSU") from the Actions drop-down. This will assign the selected derivative to the designated group.

### 6. Assign Media to Multiple Groups **(Optional)**:
- If needed, you can create actions for multiple groups and assign media to different or multiple groups by selecting the appropriate actions from the drop-down.
---
## d. Configure apache2 php.ini:
We go back to commandline and perform changes bellow:

#### 1. Ensure you have set maxiumum file size
- **upload size and max post size:**
  - ```sudo nano /etc/php/8.3/apache2/php.ini```
  - ```change post_max_size = 8M to post_max_size = 200M```
  - ```change upload_max_filesize = 8M to upload_max_filesize = 200M```
  - ```change max_file_uploads = 200 to an appropriate number (1000?)```
  - ```change memory_limit = 128M to memory_limit = 512M```

#### 2. restart apache and tomcat, daemon-reload, cache rebuild
- ```sudo systemctl restart apache2 tomcat```
- ```sudo systemctl daemon-reload```
- ```drush cr```
________________________________________
# re-islandora Workbench to be on V1.0.0:
- ```cd /opt/drupal/islandora-starter-site```
- ```sudo chmod -R 775 /opt/drupal/islandora-starter-site/web/sites/default```
- ```sudo chmod 640/opt/drupal/islandora-starter-site/web/sites/default/settings.php```
#### Remove dev version and install V1 cause dev version is not determined by workbench anymore:

- remove `mjordan/islandora_workbench_integration` from composer.json, and remove `comma` on line before that
    - ```sudo nano composer.json```
- Then update the composer json:
  - ```sudo -u www-data composer update```

#### Re-install and enable(Running command bellow will get V1 ) 
- ```sudo -u www-data composer require mjordan/islandora_workbench_integration```
- ```drush en -y islandora_workbench_integration```
- ```drush cr```
- ```sudo systemctl restart apache2 tomcat postgresql```
- ```sudo systemctl daemon-reload```

#### enable rest endpoints for workbench then rebuild the cache:
- ```drush cim -y --partial --source=/opt/drupal/islandora-starter-site/web/modules/contrib/islandora_workbench_integration/config/optional```
- ```drush cr -y```

#### If you had issue with number of file uploads check apache setting at /etc/php/8.3/apache2/php.ini
- ```sudo nano /etc/php/8.3/apache2/php.ini```
- ```max_file_uploads = ???```
________________________________________
# Fix postgresql mimic_implicite error:
mimic_implicite for postgresql error occures while creating new content, After groupmedia module installaion, causes the content not to be created in postgresql database. here are steps to resolve it:

#### Copy the fixed postgresql edited php files over:
- ```sudo cp /mnt/shared/configs/postgresql/Connection.php /opt/drupal/islandora-starter-site/web/core/modules/pgsql/src/Driver/Database/pgsql/```
- ```sudo cp /mnt/shared/configs/postgresql/Select.php /opt/drupal/islandora-starter-site/web/core/modules/pgsql/src/Driver/Database/pgsql/```
- ```drush cr```
- ```sudo systemctl daemon-reload```
- ```sudo systemctl restart apache2 postgresql```
- ```sudo systemctl status apache2 postgresql```
________________________________________
# Configure default Flysystem to a mounted Storage:
Need to be decided later
________________________________________
# Run workbench ingest:
After running our transformation tools, we are ready to ingest the data. To do this, follow the steps below:

### 1. Create custom fields:
Because we have custom fields that are not part of the default Drupal fields in the database tables, Workbench will throw an error stating "Headers require a matching Drupal fields name." Therefore, we need to create them using any of the methods below:

- **On GUI (Slow process, not recommended):**
  - Navigate to structure>Content types> Repository items> manage fields> add field
 
- **Batch ingest fields with json configuration scrips:**
  - **Install the field_create Module:** 

    - ```sudo -u www-data composer require 'drupal/field_create:^1.0'```

  - **Enable modules:** ```drush en field_create field_create_from_json```

  - **Create a JSON configuration script to define fields with specific data types:**

  - **Create fields:**
     - Navigate to configurations>delvelopment>add fields programmatically> under Content dropdown> copy json configuration for creating fields> Click save Configuration
     - Then under Action tab select node from dropdown > Click Create fields now
       - if json configurations where correct it will show you message that says: **Processed fields for node.**


     - Json format for creating fields with different data types:
  - **Example JSON syntax for creating fields:**
```json
{
 "field_name": { # Machine name of the field
   "name": "field_name", #Machine name of the field
   "label": "field name", #Enter name of the field without '_' as a field lable name
   "type": "text", # type of the field can be assigned in "type"
   "force": true,
   "bundles": {
     "islandora_object": { #islandora content type
       "label": "islandora object" #description for islandora content type
     }
   }
 }
}
```
### 2. now run the workbench to ingest our content to the server:
   - ```cd islandora_workbench```
   - ```./workbench --config LDLingest.yml```
