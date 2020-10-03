#!/bin/bash
apt install make
python -m pip install --user awscli
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer
echo "Set your aws configuration here, would you like to do this? [yn]"
read answer
if [ "$answer" == y ]; then
  aws configure
fi
echo "Do you need a new bucket to use? this may destroy data, beware! [yn]"
read 2answer
if [ "$2answer" == y ]; then
  aws s3api create-bucket --bucket hunting-loot --region us-west-2
fi
echo "You are ready to rock and roll. Run ./the_hunting.sh and stay safe!"