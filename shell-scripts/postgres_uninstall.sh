sudo service postgresql stop
sudo systemctl stop postgresql
sudo apt-get remove postgresql postgresql-client postgresql-server
sudo rm -rf /etc/postgresql/14
sudo rm -rf /var/lib/postgresql/14

#remove postgres user and groups:
sudo userdel postgres
sudo groupdel postgres
