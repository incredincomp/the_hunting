#!/bin/bash -
#Shouldnt need to be ran in axiom droplet
#this is for install and use on ubuntu 20.04 for testing
usage() { logo; echo -e "Usage: ./install.sh -[i]\nOptions:\n  -i\t-\tinstall everything\n  -u\t-\tupdate everything\n  -p\t-\tinstall pre_reqs\n  -t\t-\tinstall tools\n  -w\t-\tupdate wordlists\n  -a\t-\tupdate all tools\n  -l\t-\tless LICENSE\n" 1>&2; exit 1; }
# niiiiice @1efty
while [[ $1 ]]; do
	echo "Handling [$1]..."
	case "$1" in
    --install)
        install
        ;;
    --update_hunting)
			  update_the_hunting
		  	;;
    --pre_reqs)
        pre_reqs
	  		;;
    --install_tools)
        install_tools
  			;;
    --update_wordlists)
        update_wordlists
	  		;;
    --update_all)
        update_all_tools
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

#shift $((OPTIND - 1))

update_all_tools(){
# Probably need to add some uname checks and then set up package repo.
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
install_chromium(){
  # Probably need to add some uname checks and then set up package repo.
  type -P chromium &>/dev/null || sudo snap install chromium
}
install_tools(){
  cd ./temp
  install_amass
  install_gobuster
  install_nuclei
  install_subjack
  install_chromium
  install_aquatone
  install_httprobe
  cd ..
}

install(){
  update_all_tools
  pre_reqs
  install_tools
}
