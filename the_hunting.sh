#!/bin/bash
#===============================================================================
#
#          FILE: the_hunting.sh
#
#         USAGE: ./the_hunting.sh
#
#   DESCRIPTION:
#          borrowed some stuff and idea of automated platform from
#          lazyrecon https://github.com/nahamsec/lazyrecon. Got idea to automate
#          my workflow from countless bb folk, most notibly and recently from
#          @hakluke on his "how to crush bug bounties in your first 12 months"
#          which you can find here https://youtu.be/u_4FUs2vlKg?t=20009
#          thanks everyone
#
#       OPTIONS: ---
#  REQUIREMENTS: amass, gobuster, subjack, aquatone, httprobe, dirb, nmap,
#                nuclei, and parallel on ubuntu 20.04 or axiom droplet
#
#          BUGS:
#         NOTES: v0.1.1
#        AUTHOR: @incredincomp
#  ORGANIZATION:
#       CREATED: 08/27/2020 16:55:54
#      REVISION: 08/29/2020 11:06:00
#     LICENSING:
#===============================================================================
clear
set -o nounset                              # Treat unset variables as an error
set -e
#set -xv                                    # Uncomment to print script in console for debug

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

# borrowed some stuff and general idea of automated platform from lazyrecon https://github.com/nahamsec/lazyrecon
auquatoneThreads=8
subdomainThreads=15
subjackThreads=15
httprobeThreads=50
chromiumPath=/snap/bin/chromium

if [ -s ./slack_url.txt ]
then
  slack_url=$(<slack_url.txt)
else
  slack_url=""
fi

logo(){
echo "${red}the_hunting.sh${reset}"
}

target=""
subreport=""
usage() { logo; echo -e "Usage: ./the_hunting.sh -d <target domain> [-e] [excluded.domain.com,other.domain.com]\nOptions:\n  -e\t-\tspecify excluded subdomains\n " 1>&2; exit 1; }

while getopts ":d:e" o; do
    case "${o}" in
        d)
            target="$OPTARG"
            ;;
        e)
            set -f
            IFS=","
            excluded+=($OPTARG)
            unset IFS
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND - 1))

if [ -z "$target" ] && [ -z ${subreport[*]} ]; then
   usage; exit 1;
fi

excludedomains(){
  if [ -z "$excluded" ]; then
    echo "No domains have been excluded."
  else
    echo "Excluding domains (if you set them with -e)..."
    IFS=$'\n'
    # prints the $excluded array to excluded.txt with newlines
    printf "%s\n" "${excluded[*]}" > ./"$target"/excluded.txt
    # this form of grep takes two files, reads the input from the first file, finds in the second file and removes
    grep -vFf ./"$target"/excluded.txt ./"$target"/alldomains.txt > ./"$target"/alldomains2.txt
    mv ./"$target"/alldomains2.txt ./"$target"/alldomains.txt
    #rm ./$domain/$foldername/excluded.txt # uncomment to remove excluded.txt, I left for testing purposes
    echo "Subdomains that have been excluded from discovery:"
    printf "%s\n" "${excluded[@]}"
    unset IFS
  fi
}
# parents
run_amass(){
  echo "${yellow}Running Amass enum...${reset}"
  amass enum -norecursive --passive --silent -dir ./targets/"$target"/"$foldername"/subdomain_enum/amass/ -oA ./targets/"$target"/"$foldername"/subdomain_enum/amass/amass-"$todate" -d https://"$target"
  cat ./targets/"$target"/"$foldername"/subdomain_enum/amass/amass-"$todate".txt >> ./targets/"$target"/"$foldername"/alldomains.txt
  echo "${green}Amass enum finished.${reset}"
}

#gobuster vhost broken
run_gobuster_vhost(){
  echo "${yellow}Running gobuster vhost...${reset}"
  gobuster vhost -u "$target" -w wordlists/dns-Jhaddix.txt -a "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0" -k -np -o ./targets/"$target"/"$foldername"/subdomain_enum/gobuster/gobuster_vhost-"$todate".txt
  cat ./targets/"$target"/"$foldername"/subdomain_enum/gobuster/gobuster_vhost-"$todate".txt >> ./targets/"$target"/"$foldername"/alldomains.txt
  echo "${green}gobuster vhost finished.${reset}"
}

run_gobuster_dns(){
  echo "${yellow}Running gobuster dns...${reset}"
  gobuster dns -d "$target" -w wordlists/dns-Jhaddix.txt -z -q -t "$subdomainThreads" -o ./targets/"$target"/"$foldername"/subdomain_enum/gobuster/gobuster_dns-"$todate".txt
  cat ./targets/"$target"/"$foldername"/subdomain_enum/gobuster/gobuster_dns-"$todate".txt >> ./targets/"$target"/"$foldername"/alldomains.txt
  echo "${green}gobuster dns finished.${reset}"
}

run_subjack(){
  echo "${yellow}Running subjack...${reset}"
  $HOME/go/bin/subjack -a -w ./targets/"$target"/"$foldername"/alldomains.txt -ssl -t "$subjackThreads" -m -timeout 15 -c "$HOME/go/src/github.com/haccer/subjack/fingerprints.json" -o ./targets/"$target"/"$foldername"/subdomain-takeover-results.json -v
  echo "${green}subjack finished.${reset}"
}

run_httprobe(){
  echo "${yellow}Running httprobe...${reset}"
  cat ./targets/"$target"/"$foldername"/alldomains.txt | httprobe -c "$httprobeThreads" >> ./targets/"$target"/"$foldername"/responsive-domains-80-443.txt
  echo "${green}httprobe finished.${reset}"
}

run_aqua(){
  echo "${yellow}Running aquatone...${reset}"
  cat ./targets/"$target"/"$foldername"/responsive-domains-80-443.txt | aquatone -chrome-path $chromiumPath -out ./targets/"$target"/aqua/aqua_out -threads $auquatoneThreads -silent -http-timeout 6000
  echo "${green}aquatone finished...${reset}"
}

run_gobuster_dir(){
  echo "${yellow}Running gobuster dir...${reset}"
  read_direct_wordlist | parallel --results ./targets/"$target"/"$foldername"/directory_fuzzing/gobuster/ gobuster dir -z -q -u {} -w ./wordlists/directory-list.txt -f -k -e -r -a "Mozilla/5.0 \(X11\; Ubuntu\; Linux x86_64\; rv\:80.0\) Gecko/20100101 Firefox/80.0"
  echo "${green}gobuster dir finished...${reset}"
}

run_dirb(){
  true
}

run_nuclei(){
  true
}

run_nmap(){
  true
}

notify(){
  if [ -z "$slack_url" ]; then
    echo "${red}Notifications not set up. Add your slack url to ./slack_url.txt${reset}"
  else
    data1=''{\"text\":\"Your\ scan\ of\ "'"$target"'"\ is\ complete!\"}''
    curl -X POST -H 'Content-type: application/json' --data "$data1" https://hooks.slack.com/services/"$slack_url"
  fi
}

read_direct_wordlist(){
  cat ./targets/"$target"/"$foldername"/responsive-domains-80-443.txt
}
# children
subdomain_enum(){
#Amass https://github.com/OWASP/Amass
  run_amass &
#Gobuster trying to make them run at same time
  run_gobuster_vhost
  wait
  run_gobuster_dns
  true
}

sub_takeover(){
  run_subjack
}

target_valid(){
  run_httprobe
}

webapp_valid(){
  run_aqua
}
fuzz_em(){
  run_gobuster_dir
  run_dirb
}

webapp_scan(){
  run_nuclei
}

port_scan(){
  run_nmap
}

# main func's
recon(){
  subdomain_enum
  sub_takeover
  webapp_valid
}

scanning(){
  port_scan
  fuzz_em
  webapp_scan
}

main(){
  clear
  logo
  cd ./targets && if [ -d "./"$target"" ]
  then
    echo "This is a known target. Making a new directory with todays date."
  else
    mkdir ./"$target"
  fi && cd ..

  mkdir ./targets/"$target"/"$foldername"
  mkdir ./targets/"$target"/"$foldername"/aqua_out/
  mkdir ./targets/"$target"/"$foldername"/aqua_out/parsedjson/
  mkdir ./targets/"$target"/"$foldername"/subdomain_enum/
  mkdir ./targets/"$target"/"$foldername"/subdomain_enum/amass/
  mkdir ./targets/"$target"/"$foldername"/subdomain_enum/gobuster/
  mkdir ./targets/"$target"/"$foldername"/screenshots/
  mkdir ./targets/"$target"/"$foldername"/directory_fuzzing/
  mkdir ./targets/"$target"/"$foldername"/directory_fuzzing/gobuster/
  touch ./targets/"$target"/"$foldername"/responsive-domains-80-443.txt
  touch ./targets/"$target"/"$foldername"/subdomain-takeover-results.json
  touch ./targets/"$target"/"$foldername"/alldomains.txt
  touch ./targets/"$target"/"$foldername"/temp.txt
  touch ./targets/"$target"/"$foldername"/temp-tmp.txt
  touch ./targets/"$target"/"$foldername"/temp-domain.txt
  touch ./targets/"$target"/"$foldername"/ipaddress.txt
  touch ./targets/"$target"/"$foldername"/temp-clean.txt

  recon "$target"
  scanning "$target"
  notify
  echo "${green}Scan for "$target" finished successfully${reset}"
  duration=$SECONDS
  echo "Completed in : $((duration / 60)) minutes and $((duration % 60)) seconds."
  rm -rf ./targets/incredincomp.com
  stty sane
  tput sgr0
}
todate=$(date +"%Y-%m-%d")
path=$(pwd)
foldername="$todate"
main "$target"
