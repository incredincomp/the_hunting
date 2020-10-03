#!/bin/bash
sudo apt install make
cd ./temp
if [ -d "./aws" ]; then
  true
else
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install -i /usr/local/aws-cli -b /usr/local/bin
  export PATH="${PATH}:/usr/local/aws-cli/v2/current/bin"
fi
cd ..
source ~/.bashrc
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer
aws_config() {
  echo "Set your aws configuration here, would you like to do this? [yn]"
  read answer
  if [ "$answer" == y ]; then
    aws configure --profile the_hunting
  fi
}
aws_create() {
  echo "Do you need a new bucket to use? this may destroy data, beware! [yn]"
  read answer2
  if [ "$answer2" == y ]; then
    aws s3api create-bucket --bucket hunting-loot
  fi
  echo "You are ready to rock and roll. Run ./the_hunting.sh and stay safe!"
}
aws_config
aws_create
