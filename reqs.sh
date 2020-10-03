#!/bin/bash
sudo apt install make python3-pip
python3 -m pip install --user awscli
export PATH="${PATH}:/root/.local/bin"
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer
echo "Set your aws configuration here, would you like to do this? [yn]"
read answer
if [ "$answer" == y ]; then
  aws configure set region us-west-2
fi
echo "Do you need a new bucket to use? this may destroy data, beware! [yn]"
read answer2
if [ "$answer2" == y ]; then
  aws s3api create-bucket --bucket hunting-loot --region us-west-2
fi
echo "You are ready to rock and roll. Run ./the_hunting.sh and stay safe!"
