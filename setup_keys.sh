#!/bin/bash
mkdir -p ~/.ssh/vagrant_keys
cp /vagrant/.vagrant/machines/firewall/virtualbox/private_key ~/.ssh/vagrant_keys/firewall
cp /vagrant/.vagrant/machines/webserver/virtualbox/private_key ~/.ssh/vagrant_keys/webserver
cp /vagrant/.vagrant/machines/database/virtualbox/private_key ~/.ssh/vagrant_keys/database
cp /vagrant/.vagrant/machines/client/virtualbox/private_key ~/.ssh/vagrant_keys/client
chmod 600 ~/.ssh/vagrant_keys/*
echo "SSH-nycklar kopierade och klara!"
