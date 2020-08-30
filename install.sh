#!/bin/bash -
#Shouldnt need to be ran in axiom droplet
#this is for install and use on ubuntu 20.04 for testing
apt update && apt upgrade -y
#prereqs
apt install chromium -y

cd ./temp/
wget https://golang.org/dl/go1.15.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.15.linux-amd64.tar.gz

echo "export PATH=$PATH:/usr/local/go/bin" >> $HOME/.bashrc
source $HOME/.bashrc


# tool install
snap install amass
git clone https://github.com/OJ/gobuster
cd ./gobuster/
go get && go build
make linux
cd ./build/gobuster-linux-amd64
sudo cp gobuster /usr/bin/gobuster
