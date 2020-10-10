#!/bin/bash -
set -e
#set -xv                       # Uncomment to print script in console for debug
#Shouldnt need to be ran in axiom droplet
#this is for install and use on ubuntu 20.04 for testing
usage() {
  echo -e "Usage: ./install.sh -[i]\nOptions:\n  -i\t-\tinstall everything\n  -u\t-\tupdate everything\n  -p\t-\tinstall pre_reqs\n  -t\t-\tinstall tools\n  -w\t-\tupdate wordlists\n  -a\t-\tupdate all tools\n  -l\t-\tless LICENSE\n" 1>&2
  exit 1
}

# setting up platform/system checks
dist=$(lsb_release -is)

function update_all_tools() {
  # Probably need to add some uname checks and then set up package repo.
  apt update && apt upgrade -y
}

function update_the_hunting() {
  git pull
}

#prereqs
function pre_reqs() {
  apt update && apt upgrade -y
  apt install sudo wget git unzip parallel openjdk-8-jdk build-essential s3fs -y
}

# tool install
function install_docker() {
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  apt-get update
  apt-get install docker-ce docker-ce-cli containerd.io
}

function install_chromium() {
  # https://askubuntu.com/questions/1204571/chromium-without-snap
  echo "" >> /etc/apt/sources.lists.d/debian.list
  cat >/etc/apt/sources.lists.d/debian.list <<EOF
deb http://ftp.debian.org/debian buster main
deb http://ftp.debian.org/debian buster-updates main
deb http://ftp.debian.org/debian-security buster/updates main
EOF

  # add debian signing keys
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys DCC9EFBF77E11517
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AA8E81B4331F7F50
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 112695A0E562B32A

  # configure apt pinning
  cat >/etc/apt/preferences.d/chromium.pref <<EOF
# Note: 2 blank lines are required between entries
Package: *
Pin: release a=focal
Pin-Priority: 500


Package: *
Pin: origin "ftp.debian.org"
Pin-Priority: 300


# Pattern includes 'chromium', 'chromium-browser' and similarly
# named dependencies:
Package: chromium*
Pin: origin "ftp.debian.org"
Pin-Priority: 700
EOF

  apt update && apt install chromium
}

function snap_install_chrome() {
snap install chromium
}
function install_amass() {
  curl -sSL https://github.com/OWASP/Amass/releases/download/v3.10.4/amass_linux_amd64.zip -o amass.zip
  unzip amass.zip
  mv amass_linux_amd64/amass /usr/local/bin/amass
}

function install_gobuster() {
  git clone https://github.com/OJ/gobuster
  cd ./gobuster/
  go get && go build
  make linux
  cd ./build/gobuster-linux-amd64
  sudo cp gobuster /usr/bin/gobuster
}

function install_subjack() {
  go get github.com/haccer/subjack
  echo 'alias subjack="~/go/bin/subjack"' >>$HOME/.bashrc
}

function install_httprobe() {
  go get -u github.com/tomnomnom/httprobe
  alias httprobe="~/go/bin/httprobe"
}

function install_aquatone() {
  wget https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip
  unzip aquatone_linux_amd64_1.7.0.zip
  mv aquatone /usr/local/bin/aquatone
}

function install_nuclei() {
  curl -sSL https://github.com/projectdiscovery/nuclei/releases/download/v2.1.1/nuclei_2.1.1_linux_amd64.tar.gz -o nuclei.tar.gz
  tar -xzvf nuclei.tar.gz
  mv nuclei /usr/local/bin
  rm -rf nuclei.tar.gz
  nuclei -version
}

function install_subfinder() {
  git clone https://github.com/projectdiscovery/subfinder.git
  cd subfinder/v2/cmd/subfinder
  go build .
  mv subfinder /usr/local/bin/
}

function install_jq() {
  wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
  mv ./jq-linux64 /usr/local/bin/jq
  chmod a+x /usr/local/bin/jq
}

function install_awscli() {
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
}
function install_zap() {
  wget https://github.com/zaproxy/zaproxy/releases/download/v2.9.0/ZAP_2.9.0_Crossplatform.zip
  unzip ZAP_2.9.0_Crossplatform.zip -d ~/zap/
}
function install_go() {
  wget https://golang.org/dl/go1.15.2.linux-amd64.tar.gz
  tar -C /usr/local -xzf go1.15.2.linux-amd64.tar.gz
  #export PATH=$PATH:/usr/local/go/bin
  #source $HOME/.bashrc
}
function snap_install_go() {
  snap install go --classic
}
function install_tools() {
  cd ./temp
  if [ "$dist" == "Ubuntu" ]; then
    snap_install_chrome
  else
    install_chromium
  fi
  if [ "$dist" == "Ubuntu" ]; then
    snap_install_go
  else
    install_go
  fi
  install_amass
  install_gobuster
  install_nuclei
  install_subjack
  install_subfinder
  install_aquatone
  install_httprobe
  install_jq
  install_zap
  #finish_s3fs
  install_awscli
  cd ..
}

function install_all() {
  pre_reqs
  install_tools
}

function parse_args() {
  # niiiiice @1efty
  while [[ $1 ]]; do
    echo "Handling [$1]..."
    case "$1" in
    --install)
      install_all
      shift
      ;;
    --update_hunting)
      update_the_hunting
      shift
      ;;
    --pre_reqs)
      pre_reqs
      shift
      ;;
    --install_tools)
      install_tools
      shift
      ;;
    --update_wordlists)
      update_wordlists
      shift
      ;;
    --update_all)
      update_all_tools
      shift
      ;;
    --license)
      less ./LICENSE
      exit 1
      ;;
    *)
      echo "Error: Unknown option: $1" >&2
      exit 1
      ;;
    esac
  done
}

function main() {
  parse_args $@
}

main $@
