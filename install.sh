#!/bin/bash -
#Shouldnt need to be ran in axiom droplet
#this is for install and use on ubuntu 20.04 for testing
apt update && apt upgrade -y
#prereqs
snap install chromium
apt install parallel -y

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

cd ../../temp
go get github.com/haccer/subjack
echo 'alias subjack="~/go/bin/subjack"' >> $HOME/.bashrc

go get -u github.com/tomnomnom/httprobe
alias httprobe="~/go/bin/httprobe"

wget https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/directory-list-lowercase-2.3-big.txt
mv directory-list-lowercase-2.3-big.txt ../wordlists/directory-list.txt

wget https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip
unzip aquatone_linux_amd64_1.7.0.zip
mv aquatone /usr/local/bin/aquatone

git clone https://github.com/projectdiscovery/nuclei.git
cd nuclei/cmd/nuclei/
go build .
mv nuclei /usr/local/bin/
cd ../../../temp
