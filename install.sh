#!/bin/bash -
#Shouldnt need to be ran in axiom droplet
#this is for install and use on ubuntu 20.04 for testing
usage() { logo; echo -e "Usage: ./install.sh -[i]\nOptions:\n  -i\t-\tinstall everything\n  -u\t-\tupdate everything\n  -p\t-\tinstall pre_reqs\n  -t\t-\tinstall tools\n  -w\t-\tupdate wordlists\n  -a\t-\tupdate all tools\n  -l\t-\tless LICENSE\n" 1>&2; exit 1; }

while getopts ":i:u:p:t:w:a" o; do
    case "${o}" in
        i)
            install
            ;;
        u)
            update_the_hunting
            ;;
        p)
            pre_reqs
            ;;
        t)
            install_tools
            ;;
        w)
            update_wordlists
            ;;
        a)
            update_all_tools
            ;;
        l)
            less ./LICENSE
            exit 1
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND - 1))

update_all_tools(){
  apt update && apt upgrade -y
  snap refresh
}
update_the_hunting(){
  git pull
}
#prereqs
pre_reqs(){
  snap install chromium
  apt install parallel -y
  go_lang
}

go_lang(){
  wget https://golang.org/dl/go1.15.linux-amd64.tar.gz
  sudo tar -C /usr/local -xzf go1.15.linux-amd64.tar.gz
  echo "export PATH=$PATH:/usr/local/go/bin" >> $HOME/.bashrc
  source $HOME/.bashrc
}

# tool install
install_amass(){
  snap install amass
}
install_gobuster(){
  git clone https://github.com/OJ/gobuster
  cd ./gobuster/
  go get && go build
  make linux
  cd ./build/gobuster-linux-amd64
  sudo cp gobuster /usr/bin/gobuster
}
install_subjack(){
  go get github.com/haccer/subjack
  echo 'alias subjack="~/go/bin/subjack"' >> $HOME/.bashrc
}
install_httprobe(){
  go get -u github.com/tomnomnom/httprobe
  alias httprobe="~/go/bin/httprobe"
}
install_wordlists(){
  wget https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/directory-list-lowercase-2.3-big.txt
  mv directory-list-lowercase-2.3-big.txt ../wordlists/directory-list.txt
}
install_aquatone(){
  wget https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip
  unzip aquatone_linux_amd64_1.7.0.zip
  mv aquatone /usr/local/bin/aquatone
}
install_nuclei(){
  git clone https://github.com/projectdiscovery/nuclei.git
  cd nuclei/cmd/nuclei/
  go build .
  mv nuclei /usr/local/bin/
  cd ../../../
}

install_tools(){
  cd ./temp
  install_amass
  install_gobuster
  install_nuclei
  install_subjack
  install_aquatone
  install_httprobe
  install_wordlists
  cd ..
}

update_wordlists(){
  true
}

install(){
  update_all_tools
  pre_reqs
  install_tools
}
