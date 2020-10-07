#!/bin/bash
if [ -s "${PWD}""/backup-files/s3-bucket.txt" ]; then
  S3_BUCKET=" "
else
  S3_BUCKET="$(cat "${PWD}"/backup-files/s3-bucket.txt)"
fi
rand=$(openssl rand -hex 16)
function install_make() {
  sudo apt install make
}
function install_awscli() {
  cd ./temp
  if [ -d "./aws" ]; then
    true
  else
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install -i /usr/local/aws-cli -b /usr/local/bin
    export PATH="${PATH}:/usr/local/aws-cli/v2/current/bin"
    source ~/.bashrc
  fi
  cd ..
  aws_config
  aws_create
  cp -r ~/.aws ./backup-files/
}
function install_packer() {
  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
  sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
  sudo apt-get update && sudo apt-get install packer
}
function aws_config() {
  echo "Set your aws configuration here, would you like to do this? [yn]"
  read answer
  echo "You need to use us-east-1 for now.. sorry."
  if [ "$answer" == y ]; then
    aws configure --profile the_hunting
    export AWS_PROFILE=the_hunting
  fi
}
function aws_create() {
  echo "Do you need a new bucket to use? this may destroy data, beware! [yn]"
  read answer2
  if [ "$answer2" == y ] && [ "$S3_BUCKET" == " " ]; then
    $S3_BUCKET=$(aws s3api create-bucket --bucket hunting-loot-"$rand" --profile the_hunting | jq -r ".Location" | tr -d /)
    echo "$S3_BUCKET" > ./backup-files/s3-bucket.txt
    echo "http://""$S3_BUCKET"".s3.us-east-1.amazonaws.com" > ./backup-files/s3-endpoint.txt
    aws s3api put-public-access-block --region us-east-1 --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true --bucket "$S3_BUCKET"
  fi
  echo "You are ready to rock and roll. Run 'make build' and wear your mask!"
}
function compile_s3fs() {
  git clone https://github.com/s3fs-fuse/s3fs-fuse.git
  cd s3fs-fuse
  ./autogen.sh
  ./configure
  make
  sudo make install
}
function finish_s3fs() {
  echo "$S3_BUCKET"" /root/the_hunting/s3-booty fuse.s3fs _netdev,allow_other,url=""$S3_BUCKET"" 0 0" >> /etc/fstab
}
install_make
install_packer
install_awscli
