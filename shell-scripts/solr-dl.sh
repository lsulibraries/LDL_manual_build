#!/bin/bash
cd /opt
sudo wget https://www.apache.org/dyn/closer.lua/solr/solr/9.6.0/solr-9.6.0.tgz?action=download
sudo mv solr-9.6.0.tgz?action=download solr-9.6.0.tgz
sudo tar xzf solr-9.6.0.tgz solr-9.6.0/bin/install_solr_service.sh --strip-components=2