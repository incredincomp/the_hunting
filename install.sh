#!/bin/bash -
#Shouldnt need to be ran in axiom droplet
#this is for install and use on ubuntu 20.04 for testing
usage() {
  echo -e "Usage: ./install.sh -[i]\nOptions:\n  -i\t-\tinstall everything\n  -u\t-\tupdate everything\n  -p\t-\tinstall pre_reqs\n  -t\t-\tinstall tools\n  -w\t-\tupdate wordlists\n  -a\t-\tupdate all tools\n  -l\t-\tless LICENSE\n" 1>&2
  exit 1
}

function update_all_tools() {
  # Probably need to add some uname checks and then set up package repo.
  apt update && apt upgrade -y
  snap refresh
}

function update_the_hunting() {
  git pull
}

#prereqs
function pre_reqs() {
  apt update && apt upgrade -y
  apt install snapd sudo wget git make unzip parallel golang jq -y
  snap install chromium
}

# tool install
function install_amass() {
  snap install amass
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
  nuclei -h
}

function install_subfinder() {
  git clone https://github.com/projectdiscovery/subfinder.git
  cd subfinder/v2/cmd/subfinder
  go build .
  mv subfinder /usr/local/bin/
}

function install_chromium() {
  # Probably need to add some uname checks and then set up package repo.
  type -P chromium &>/dev/null || sudo snap install chromium
}

function install_tools() {
  cd ./temp
  install_amass
  install_gobuster
  install_nuclei
  install_subjack
  install_chromium
  install_subfinder
  install_aquatone
  install_httprobe
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
