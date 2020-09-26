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
#          thanks everyone, SPECIALLY @1efty!!! Thanks ;)
#
#       OPTIONS: ---
#  REQUIREMENTS: amass, gobuster, subjack, aquatone, httprobe, dirb, nmap,
#                nuclei, chromium, and parallel on ubuntu 20.04 or just
#                use an axiom droplet
#
#          BUGS:
#         NOTES: v0.3.2
#        AUTHOR: @incredincomp
#  ORGANIZATION:
#       CREATED: 08/27/2020 16:55:54
#      REVISION: 09/10/2020 00:08:00
#     LICENSING: the_hunting Copyright (C) 2020  @incredincomp
#                This program comes with ABSOLUTELY NO WARRANTY;
#                for details, type `./the_hunting.sh -l'.
#                This is free software, and you are welcome to redistribute
#                it under certain conditions;
#                for details, type `./the_hunting.sh -l'.
#===============================================================================
#set -o nounset                 # Treat unset variables as an error
set -e
#set -xv                       # Uncomment to print script in console for debug

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

alias httprobe="~/go/bin/httprobe"
# borrowed some stuff and general idea of automated platform from lazyrecon
# https://github.com/nahamsec/lazyrecon
auquatoneThreads=8
subdomainThreads=15
subjackThreads=15
httprobeThreads=50

# Good call @1efty
CHROMIUM="${CHROMIUM:-"chromium"}"
chromiumPath="$(which $CHROMIUM)"

type -P parallel &>/dev/null || sudo apt install parallel -y

if [ -s ./slack_url.txt ]; then
  slack_url=$(<slack_url.txt)
else
  slack_url=""
fi
if [ -s ./bot_user_oauth_at.txt ]; then
  bot_token=$(<bot_user_oauth_at.txt)
else
  bot_token=""
fi
if [ -s ./slack_channel.txt ]; then
  slack_channel=$(<slack_channel.txt)
else
  slack_channel=""
fi

target=""
subdomain_scan_target=""
declare -a excluded=()
usage() {
  echo -e "Usage: ./the_hunting.sh -d <target domain> [-e] [excluded.domain.com,other.domain.com]\nOptions:\n  -e\t-\tspecify excluded subdomains\n " 1>&2
  exit 1
}
# need help taking multiple options
#while [[ $1 ]]; do
#	echo "Handling [$1]..."
#	case "$1" in
#    --target)
#        target="$OPTARG"
#        ;;
#    --exclude)
#			  excluded="$OPTARG"
#		  	;;
#    --scan)
#        set -f
#        IFS=","
#        subdomain_scan_target+=($OPTARG)
#        unset IFS
#        if [ -s ./deepdive/subdomain.txt ]; then
#          mv ./deepdive/subdomain.txt ./deepdive/lastscan.txt
#        fi
#        IFS=$'\n'
#        for u in "${subdomain_scan_target[@]}"; do
#          printf "%s\n" "$u" >> ./deepdive/subdomain.txt
#        done
#        unset IFS
#        subdomain_scan_target_file="./deepdive/subdomain.txt"
#        ;;
#    --file)
#        subdomain_scan_target_file="$OPTARG"
#  			;;
#    --file-all)
#        all_subdomain_scan_target_file="$OPTARG"
#	  		;;
#    --license)
#        less ./LICENSE
#        exit 1
#	  		;;
#    *)
#        echo "Error: Unknown option: $1" >&2
#        usage
#	  		exit 1
#	  		;;
#	esac
#done
while getopts ":d:s:e:f:n:l" o; do
  case "${o}" in
  d)
    target="$OPTARG"
    ;;
  e)
    excluded="$OPTARG"
    ;;
  s)
    set -f
    IFS=","
    subdomain_scan_target+=($OPTARG)
    unset IFS
    if [ -s ./deepdive/subdomain.txt ]; then
      mv ./deepdive/subdomain.txt ./deepdive/lastscan.txt
    fi
    IFS=$'\n'
    for u in "${subdomain_scan_target[@]}"; do
      printf "%s\n" "$u" >>./deepdive/subdomain.txt
    done
    unset IFS
    subdomain_scan_target_file="./deepdive/subdomain.txt"
    ;;
  f)
    subdomain_scan_target_file="$OPTARG"
    ;;
  n)
    all_subdomain_scan_target_file="$OPTARG"
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

if [ -z "$target" ] && [[ -z ${subdomain_scan_target[*]} ]] && [ -z "$subdomain_scan_target_file" ] && [ -z "$all_subdomain_scan_target_file" ]; then
  usage
  exit 1
fi

excludedomains() {
  echo "Excluding domains (if you set them with -e)..."
  if [ -z "$excluded" ]; then
    echo "No subdomains have been exluded"
  else
    touch ./targets/"$target"/"$foldername"/excluded.txt
    #stupid cause its simple and it works
    echo $excluded | tr -s ',' '\n' >>./targets/"$target"/"$foldername"/excluded.txt
    #cp ./amass_config.ini ./amass_config.bak
    #IFS=$'\n'
    #for u in "${excluded[*]}"; do
    #printf "%s\n" "subdomain = ""$u" >> ./amass_config.ini
    #printf "%s\n" "${excluded[*]}" > ./targets/"$target"/"$foldername"/excluded.txt
    #printf "%s\n" "$u" > ./deepdive/excluded.txt
    #done
    #unset IFS
    # this form of grep takes two files, reads the input from the first file, finds in the second file and removes
    #grep -vFf ./targets/"$target"/"$foldername"/excluded.txt ./targets/"$target"/"$foldername"/responsive-domains-80-443.txt > ./targets/"$target"/"$foldername"/2responsive-domains-80-443.txt
    #mv ./targets/"$target"/"$foldername"/2responsive-domains-80-443.txt ./targets/"$target"/"$foldername"/responsive-domains-80-443.txt
    #rm ./targets/"$target"/"$foldername"/excluded.txt # uncomment to remove excluded.txt, I left for testing purposes
    echo "${green}Subdomains that have been excluded from discovery:${reset}"
    cat ./targets/"$target"/"$foldername"/excluded.txt
    #printf "%s\n" "${excluded[@]}"
    #unset IFS
    #cat ./targets/"$target"/"$foldername"/excluded.txt
  fi
}
# parents
run_amass() {
  if [ -s ./targets/"$target"/"$foldername"/excluded.txt ]; then
    amass enum -norecursive -passive -config ./amass_config.ini -blf ./targets/"$target"/"$foldername"/excluded.txt -dir ./targets/"$target"/"$foldername"/subdomain_enum/amass/ -oA ./targets/"$target"/"$foldername"/subdomain_enum/amass/amass-"$todate" -d "$target"
  else
    amass enum -norecursive -passive -config ./amass_config.ini -dir ./targets/"$target"/"$foldername"/subdomain_enum/amass/ -oA ./targets/"$target"/"$foldername"/subdomain_enum/amass/amass-"$todate" -d "$target"
  fi
  #ret=$?
  #if [[ $ret -ne 0 ]] ; then
  #notify_error
  #fi
  cat ./targets/"$target"/"$foldername"/subdomain_enum/amass/amass-"$todate".txt >>./targets/"$target"/"$foldername"/alldomains.txt
}
#new amass
run_json_amass() {
  if [ -s ./targets/"$target"/"$foldername"/excluded.txt ]; then
    amass enum -norecursive -passive -config ./amass_config.ini -blf ./targets/"$target"/"$foldername"/excluded.txt -json ./targets/"$target"/"$foldername"/subdomain_enum/amass/amass-"$todate".json -d "$target"
  else
    amass enum -norecursive -passive -config ./amass_config.ini -json ./targets/"$target"/"$foldername"/subdomain_enum/amass/amass-"$todate".json -d "$target"
  fi
  #ret=$?
  #if [[ $ret -ne 0 ]] ; then
  #notify_error
  #fi
  #cat ./targets/"$target"/"$foldername"/subdomain_enum/amass/amass-"$todate".txt >> ./targets/"$target"/"$foldername"/alldomains.txt
}
run_subfinder_json() {
  subfinder -config ./subfinder.yaml -d "$target" -o ./targets/"$target"/"$foldername"/subfinder.json -oJ -nW -all
  #ret=$?
  #if [[ $ret -ne 0 ]] ; then
  #notify_error
  #fi
}
#gobuster vhost broken
run_gobuster_vhost() {
  echo "${yellow}Running Gobuster vhost...${reset}"
  gobuster vhost -u "$target" -w ./wordlists/subdomains-top-110000.txt -a "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0" -k -o ./targets/"$target"/"$foldername"/subdomain_enum/gobuster/gobuster_vhost-"$todate".txt
  ret=$?
  if [[ $ret -ne 0 ]]; then
    notify_error
  fi
  cat ./targets/"$target"/"$foldername"/subdomain_enum/gobuster/gobuster_vhost-"$todate".txt >>./targets/"$target"/"$foldername"/alldomains.txt
  echo "${green}Gobuster vhost finished.${reset}"
}
run_gobuster_dns() {
  echo "${yellow}Running Gobuster dns...${reset}"
  gobuster dns -d "$target" -w ./wordlists/subdomains-top-110000.txt -z -q -t "$subdomainThreads" -o ./targets/"$target"/"$foldername"/subdomain_enum/gobuster/gobuster_dns-"$todate".txt
  ret=$?
  if [[ $ret -ne 0 ]]; then
    notify_error
  fi
  cat ./targets/"$target"/"$foldername"/subdomain_enum/gobuster/gobuster_dns-"$todate".txt | awk -F ' ' '{print $2}' >>./targets/"$target"/"$foldername"/alldomains.txt
  echo "${green}Gobuster dns finished.${reset}"
}
run_subjack() {
  echo "${yellow}Running subjack...${reset}"
  $HOME/go/bin/subjack -a -w ./targets/"$target"/"$foldername"/subdomains-jq.txt -ssl -t "$subjackThreads" -m -timeout 15 -c "$HOME/go/src/github.com/haccer/subjack/fingerprints.json" -o ./targets/"$target"/"$foldername"/subdomain-takeover-results.json -v
  ret=$?
  if [[ $ret -ne 0 ]]; then
    notify_error
  fi
  echo "${green}subjack finished.${reset}"
}
run_httprobe() {
  echo "${yellow}Running httprobe...${reset}"
  cat ./targets/"$target"/"$foldername"/subdomains-jq.txt | httprobe -c "$httprobeThreads" >>./targets/"$target"/"$foldername"/responsive-domains-80-443.txt
  ret=$?
  if [[ $ret -ne 0 ]]; then
    notify_error
  fi
  echo "${green}httprobe finished.${reset}"
}
run_aqua() {
  echo "${yellow}Running Aquatone...${reset}"
  cat ./targets/"$target"/"$foldername"/responsive-domains-80-443.txt | aquatone -threads $auquatoneThreads -chrome-path $chromiumPath -out ./targets/"$target"/"$foldername"/aqua/aqua_out
  ret=$?
  if [[ $ret -ne 0 ]]; then
    notify_error
  fi
  cp ./targets/"$target"/"$foldername"/aqua/aqua_out/aquatone_report.html ./targets/"$target"/"$foldername"/aquatone_report.html
  cp ./targets/"$target"/"$foldername"/aqua/aqua_out/aquatone_urls.txt ./targets/"$target"/"$foldername"/aquatone_urls.txt
  echo "${green}Aquatone finished...${reset}"
}
run_gobuster_dir() {
  #crazy headed and dangerous, untested really.. dont know what happens with output
  echo "${yellow}Running Gobuster dir...${reset}"
  read_direct_wordlist | parallel --results ./targets/"$target"/"$foldername"/directory_fuzzing/gobuster/ gobuster dir -z -q -u {} -w ./wordlists/directory-list.txt -f -k -e -r -a "Mozilla/5.0 \(X11\; Ubuntu\; Linux x86_64\; rv\:80.0\) Gecko/20100101 Firefox/80.0"
  ret=$?
  if [[ $ret -ne 0 ]]; then
    notify_error
  fi
  cat ./targets/"$target"/"$foldername"/directory_fuzzing/gobuster/1/"$target"/stdout | awk -F ' ' '{print $1}' >>./targets/"$target"/"$foldername"/live_paths.txt
  echo "${green}Gobuster dir finished...${reset}"
}
run_dirb() {
  true
}
run_nuclei() {
  echo "${yellow}Running Nuclei templates scan...${reset}"
  nuclei -v -json -l ./targets/"$target"/"$foldername"/responsive-domains-80-443.txt -t ./nuclei-templates/cves/ -t ./nuclei-templates/vulnerabilities/ -t ./nuclei-templates/security-misconfiguration/ -t ./deepdive/nuclei-templates/generic-detections/ -t ./deepdive/nuclei-templates/files/ -t ./deepdive/nuclei-templates/workflows/ -t ./deepdive/nuclei-templates/tokens/ -t ./deepdive/nuclei-templates/dns/ -o ./targets/"$target"/"$foldername"/scanning/nuclei/nuclei-results.json
  #  nuclei -v -json -l ./targets/"$target"/"$foldername"/aquatone_urls.txt -t ./nuclei-templates/vulnerabilities/ -o ./targets/"$target"/"$foldername"/scanning/nuclei/nuclei-vulnerabilties-results.json
  #  nuclei -v -json -l ./targets/"$target"/"$foldername"/aquatone_urls.txt -t ./nuclei-templates/security-misconfiguration/ -o ./targets/"$target"/"$foldername"/scanning/nuclei/nuclei-security-misconfigurations-results.json
  echo "${green}Nuclei stock cve templates scan finished...${reset}"
}
subdomain_scanning() {
  nuclei -v -json -l "$subdomain_scan_target_file" -t ./nuclei-templates/cves/ -t ./nuclei-templates/vulnerabilities/ -t ./nuclei-templates/security-misconfiguration/ -t ./nuclei-templates/generic-detections/ -t ./nuclei-templates/files/ -t ./nuclei-templates/workflows/ -t ./nuclei-templates/tokens/ -t ./nuclei-templates/dns/ -o ./deepdive/"$todate"-"$totime"-nuclei-vulns.json
}
all_subdomain_scanning() {
  nuclei -v -json -l "$all_subdomain_scan_target_file" -t ./nuclei-templates/ -o ./deepdive/"$todate"-"$totime"-nuclei-vulns.json
}
run_zap() {
  echo "${yellow}Running zap scan...${reset}"
  echo "${red} Just kidding! Working on it though.${reset}"
  echo "${green}zap scan finished...${reset}"
}
run_nmap() {
  true
}
# notifications slack
notify_finished() {
  if [ -z "$slack_url" ]; then
    echo "${red}Notifications not set up. Add your slack url to ./slack_url.txt${reset}"
  else
    echo "${yellow}Notification being generated and sent...${reset}"
    num_of_subd=$(wc <./targets/"$target"/"$foldername"/subdomains-jq.txt -l)
    data1=''{\"text\":\"Your\ scan\ of\ "'"$target"'"\ is\ complete!\ \`the\_hunting.sh\`\ found\ "'"$num_of_subd"'"\ responsive\ subdomains\ to\ scan.\"}''
    curl -X POST -H 'Content-type: application/json' --data "$data1" https://hooks.slack.com/services/"$slack_url"
    echo "${green}Notification sent!${reset}"
  fi
}
notify_subdomain_scan() {
  if [ -z "$slack_url" ]; then
    echo "${red}Notifications not set up. Add your slack url to ./slack_url.txt${reset}"
  else
    echo "${yellow}Notification being generated and sent...${reset}"
    if [ -s ./deepdive/nuclei-vulns.json ]; then
      num_of_vuln=$(wc <./deepdive/nuclei-vulns.json -l)
      data1=''{\"text\":\"Your\ subdomain\ scan\ is\ complete!\ \`the\_hunting.sh\`\ found\ "'"$num_of_vuln"'"\ vulnerabilities.\"}''
      curl -X POST -H 'Content-type: application/json' --data "$data1" https://hooks.slack.com/services/"$slack_url"
    else
      num_of_vuln=$(wc <./deepdive/"$todate"-"$totime"-nuclei-vulns.json -l)
      data1=''{\"text\":\"Your\ subdomain\ scan\ is\ complete!\ \`the\_hunting.sh\`\ found\ "'"$num_of_vuln"'"\ vulnerabilities.\"}''
      curl -X POST -H 'Content-type: application/json' --data "$data1" https://hooks.slack.com/services/"$slack_url"
    fi
  fi
  echo "${green}Notification sent!${reset}"
}
notify_error() {
  if [ -z "$slack_url" ]; then
    echo "${red}Notifications not set up. Add your slack url to ./slack_url.txt${reset}"
  else
    echo "${yellow}Error notification being generated and sent...${reset}"
    num_of_subd=$(wc <./targets/"$target"/"$foldername"/responsive-domains-80-443.txt -l)
    data1=''{\"text\":\"There\ was\ an\ error\ on\ your\ scan\ of\ "'"$target"'"!\ Check\ your\ instance\ of\ \`the\_hunting.sh\`\.\ \`the\_hunting.sh\`\ still\ found\ "'"$num_of_subd"'"\ responsive\ subdomains\ to\ scan.\"}''
    curl -X POST -H 'Content-type: application/json' --data "$data1" https://hooks.slack.com/services/"$slack_url"
    echo "${green}Notification sent!${reset}"
  fi
}

send_file() {
  if [ -z "$slack_url" ]; then
    echo "${red}Notifications not set up. Add your slack url to ./slack_url.txt${reset}"
  else
    if [ -z "$slack_channel" ] && [ -z "$bot_token" ] && [ -z "$bot_user_oauth_at" ] && [ -s ./deepdive/"$todate"-"$totime"-nuclei-vulns.json ]; then
      echo "${red}Notifications not set up."
      echo "${red}Add your slack channel to ./slack_channel.txt"
      echo "${red}Add your slack bot user oauth token to ./bot_user_oauth_at.txt${reset}"
    else
      echo "${yellow}File being sent...${reset}"
      curl -F file=@deepdive/"$todate"-"$totime"-nuclei-vulns.json -F "initial_comment=Vulns from your most recent scan." -F channels="$slack_channel" -H "Authorization: Bearer ${bot_token}" https://slack.com/api/files.upload
      echo "${green}File sent!${reset}"
    fi
  fi
}
# << remove
undo_amass_config() {
  if [ -s ./amass_config.bak ]; then
    mv ./amass_config.bak ./amass_config.ini
    #rm ./amass_config.bak
  fi
}

undo_subdomain_file() {
  if [ -s ./deepdive/subdomain.txt ]; then
    rm ./deepdive/subdomain.txt
    touch ./deepdive/subdomain.txt
  fi
}
make_csv() {
  touch ./csvs/"$target"-csv.txt
  paste -s -d ',' ./targets/"$target"/"$foldername"/responsive-domains-80-443.txt >./csvs/"$target"-csv.txt
}
# >>

read_direct_wordlist() {
  cat ./targets/"$target"/"$foldername"/aqua/aqua_out/aquatone_urls.txt
}
uniq_subdomains() {
  uniq -i ./targets/"$target"/"$foldername"/aqua/aqua_out/aquatone_urls.txt >>./targets/"$target"/"$foldername"/uniqdomains1.txt
}

double_check_excluded() {
  if [ -s ./targets/"$target"/"$foldername"/excluded.txt ]; then
    grep -vFf ./targets/"$target"/"$foldername"/excluded.txt ./targets/"$target"/"$foldername"/responsive-domains-80-443.txt >./targets/"$target"/"$foldername"/2responsive-domains-80-443.txt
    rm ./targets/"$target"/"$foldername"/responsive-domains-80-443.txt
    mv ./targets/"$target"/"$foldername"/2responsive-domains-80-443.txt ./targets/"$target"/"$foldername"/responsive-domains-80-443.txt && rm ./targets/"$target"/"$foldername"/2responsive-domains-80-443.txt
  fi
}
parse_json() {
  # ips
  cat ./targets/"$target"/"$foldername"/subfinder.json | jq -r '.ip' >./targets/"$target"/"$foldername"/"$target"-ips.txt
  #domain names
  cat ./targets/"$target"/"$foldername"/subfinder.json | jq -r '.host' >./targets/"$target"/"$foldername"/subdomains-jq.txt
}
# children
subdomain_enum() {
  echo "${yellow}Running Amass enum...${reset}"
  #Amass https://github.com/OWASP/Amass
  #run_amass
  #run_json_amass
  run_subfinder_json
  parse_json
  echo "${green}Amass enum finished.${reset}"
  #Gobuster trying to make them run at same time
  #run_gobuster_vhost
  #run_gobuster_dns
}
sub_takeover() {
  run_subjack
}
target_valid() {
  run_httprobe
}
webapp_valid() {
  run_aqua
}
fuzz_em() {
  #run_gobuster_dir
  run_dirb
}
webapp_scan() {
  run_nuclei
}
port_scan() {
  run_nmap
}
# main func's
recon() {
  subdomain_enum
  sub_takeover
}
validation() {
  target_valid
  webapp_valid
  uniq_subdomains
}
scanning() {
  port_scan
  fuzz_em
  webapp_scan
}
# graphic opening stuff
logo() {
  base64 -d <<<"4paI4paI4paI4paI4paI4paI4paI4paI4pWX4paI4paI4pWXICDilojilojilZfilojilojilojilojilojilojilojilZcgICAgICAgIOKWiOKWiOKVlyAg4paI4paI4pWX4paI4paI4pWXICAg4paI4paI4pWX4paI4paI4paI4pWXICAg4paI4paI4pWX4paI4paI4paI4paI4paI4paI4paI4paI4pWX4paI4paI4pWX4paI4paI4paI4pWXICAg4paI4paI4pWXIOKWiOKWiOKWiOKWiOKWiOKWiOKVlyAgICDilojilojilojilojilojilojilojilZfilojilojilZcgIOKWiOKWiOKVlwrilZrilZDilZDilojilojilZTilZDilZDilZ3ilojilojilZEgIOKWiOKWiOKVkeKWiOKWiOKVlOKVkOKVkOKVkOKVkOKVnSAgICAgICAg4paI4paI4pWRICDilojilojilZHilojilojilZEgICDilojilojilZHilojilojilojilojilZcgIOKWiOKWiOKVkeKVmuKVkOKVkOKWiOKWiOKVlOKVkOKVkOKVneKWiOKWiOKVkeKWiOKWiOKWiOKWiOKVlyAg4paI4paI4pWR4paI4paI4pWU4pWQ4pWQ4pWQ4pWQ4pWdICAgIOKWiOKWiOKVlOKVkOKVkOKVkOKVkOKVneKWiOKWiOKVkSAg4paI4paI4pWRCiAgIOKWiOKWiOKVkSAgIOKWiOKWiOKWiOKWiOKWiOKWiOKWiOKVkeKWiOKWiOKWiOKWiOKWiOKVlyAgICAgICAgICDilojilojilojilojilojilojilojilZHilojilojilZEgICDilojilojilZHilojilojilZTilojilojilZcg4paI4paI4pWRICAg4paI4paI4pWRICAg4paI4paI4pWR4paI4paI4pWU4paI4paI4pWXIOKWiOKWiOKVkeKWiOKWiOKVkSAg4paI4paI4paI4pWXICAg4paI4paI4paI4paI4paI4paI4paI4pWX4paI4paI4paI4paI4paI4paI4paI4pWRCiAgIOKWiOKWiOKVkSAgIOKWiOKWiOKVlOKVkOKVkOKWiOKWiOKVkeKWiOKWiOKVlOKVkOKVkOKVnSAgICAgICAgICDilojilojilZTilZDilZDilojilojilZHilojilojilZEgICDilojilojilZHilojilojilZHilZrilojilojilZfilojilojilZEgICDilojilojilZEgICDilojilojilZHilojilojilZHilZrilojilojilZfilojilojilZHilojilojilZEgICDilojilojilZEgICDilZrilZDilZDilZDilZDilojilojilZHilojilojilZTilZDilZDilojilojilZEKICAg4paI4paI4pWRICAg4paI4paI4pWRICDilojilojilZHilojilojilojilojilojilojilojilZfilojilojilojilojilojilojilojilZfilojilojilZEgIOKWiOKWiOKVkeKVmuKWiOKWiOKWiOKWiOKWiOKWiOKVlOKVneKWiOKWiOKVkSDilZrilojilojilojilojilZEgICDilojilojilZEgICDilojilojilZHilojilojilZEg4pWa4paI4paI4paI4paI4pWR4pWa4paI4paI4paI4paI4paI4paI4pWU4pWd4paI4paI4pWX4paI4paI4paI4paI4paI4paI4paI4pWR4paI4paI4pWRICDilojilojilZEKICAg4pWa4pWQ4pWdICAg4pWa4pWQ4pWdICDilZrilZDilZ3ilZrilZDilZDilZDilZDilZDilZDilZ3ilZrilZDilZDilZDilZDilZDilZDilZ3ilZrilZDilZ0gIOKVmuKVkOKVnSDilZrilZDilZDilZDilZDilZDilZ0g4pWa4pWQ4pWdICDilZrilZDilZDilZDilZ0gICDilZrilZDilZ0gICDilZrilZDilZ3ilZrilZDilZ0gIOKVmuKVkOKVkOKVkOKVnSDilZrilZDilZDilZDilZDilZDilZ0g4pWa4pWQ4pWd4pWa4pWQ4pWQ4pWQ4pWQ4pWQ4pWQ4pWd4pWa4pWQ4pWdICDilZrilZDilZ0="
}
credits() {
  print_line
  base64 -d <<<"ICAgQ3JlZGl0czogVGhhbmtzIHRvIGh0dHBzOi8vZ2l0aHViLmNvbS9PSiBodHRwczovL2dpdGh1Yi5jb20vT1dBU1AgaHR0cHM6Ly9naXRodWIuY29tL2hhY2NlcgogICBodHRwczovL2dpdGh1Yi5jb20vdG9tbm9tbm9tIGh0dHBzOi8vZ2l0aHViLmNvbS9taWNoZW5yaWtzZW4gJiBUaGUgRGFyayBSYXZlciBmb3IgdGhlaXIKICAgd29yayBvbiB0aGUgcHJvZ3JhbXMgdGhhdCB3ZW50IGludG8gdGhlIG1ha2luZyBvZiB0aGVfaHVudGluZy5zaC4="
  echo " "
  print_line
}
licensing_info() {
  base64 -d <<<"CXRoZV9odW50aW5nIENvcHlyaWdodCAoQykgMjAyMCAgQGluY3JlZGluY29tcAoJVGhpcyBwcm9ncmFtIGNvbWVzIHdpdGggQUJTT0xVVEVMWSBOTyBXQVJSQU5UWTsgZm9yIGRldGFpbHMgY2FsbCBgLi90aGVfaHVudGluZy5zaCAtbGljZW5zZScuCglUaGlzIGlzIGZyZWUgc29mdHdhcmUsIGFuZCB5b3UgYXJlIHdlbGNvbWUgdG8gcmVkaXN0cmlidXRlIGl0LgoJdW5kZXIgY2VydGFpbiBjb25kaXRpb25zOyB0eXBlIGAuL3RoZV9odW50aW5nLnNoIC1saWNlbnNlJyBmb3IgZGV0YWlscy4="
  echo " "
}
print_line() {
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  echo " "
}
open_program() {
  logo
  echo " "
  credits
  licensing_info
  print_line
}

subdomain_option() {
  clear
  open_program
  if [ ! -d ./deepdive ]; then
    mkdir ./deepdive
  fi
  touch ./deepdive/"$todate"-"$totime"-nuclei-vulns.json
  if [ -z "$subdomain_scan_target"]; then
    all_subdomain_scanning
  else
    subdomain_scanning
  fi
  notify_subdomain_scan
  send_file
  undo_subdomain_file
  duration=$SECONDS
  echo "Completed in : $((duration / 60)) minutes and $((duration % 60)) seconds."
  stty sane
  tput sgr0
}

credits() {
  print_line
  base64 -d <<<"ICAgQ3JlZGl0czogVGhhbmtzIHRvIGh0dHBzOi8vZ2l0aHViLmNvbS9PSiBodHRwczovL2dpdGh1Yi5jb20vT1dBU1AgaHR0cHM6Ly9naXRodWIuY29tL2hhY2NlcgogICBodHRwczovL2dpdGh1Yi5jb20vdG9tbm9tbm9tIGh0dHBzOi8vZ2l0aHViLmNvbS9taWNoZW5yaWtzZW4gJiBUaGUgRGFyayBSYXZlciBmb3IgdGhlaXIKICAgd29yayBvbiB0aGUgcHJvZ3JhbXMgdGhhdCB3ZW50IGludG8gdGhlIG1ha2luZyBvZiB0aGVfaHVudGluZy5zaC4="
  echo " "
  print_line
}

licensing_info() {
  base64 -d <<<"CXRoZV9odW50aW5nIENvcHlyaWdodCAoQykgMjAyMCAgQGluY3JlZGluY29tcAoJVGhpcyBwcm9ncmFtIGNvbWVzIHdpdGggQUJTT0xVVEVMWSBOTyBXQVJSQU5UWTsgZm9yIGRldGFpbHMgY2FsbCBgLi90aGVfaHVudGluZy5zaCAtbGljZW5zZScuCglUaGlzIGlzIGZyZWUgc29mdHdhcmUsIGFuZCB5b3UgYXJlIHdlbGNvbWUgdG8gcmVkaXN0cmlidXRlIGl0LgoJdW5kZXIgY2VydGFpbiBjb25kaXRpb25zOyB0eXBlIGAuL3RoZV9odW50aW5nLnNoIC1saWNlbnNlJyBmb3IgZGV0YWlscy4="
  echo " "
}

print_line() {
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  echo " "
}

open_program() {
  logo
  echo " "
  credits
  licensing_info
  print_line
}

# main
main() {
  if [[ -z "$target" ]]; then
    subdomain_option
  else #scanning only
    clear
    open_program
    if [ -d "./targets/"$target"" ]; then
      echo "$target is a known target."
    else
      mkdir ./targets/"$target"/
    fi
    if [ -z "$slack_url" ]; then
      echo "${red}Notifications not set up. Add your slack url to ./slack_url.txt${reset}"
    fi

    mkdir ./targets/"$target"/"$foldername"
    mkdir ./targets/"$target"/"$foldername"/aqua/
    mkdir ./targets/"$target"/"$foldername"/aqua/aqua_out/
    mkdir ./targets/"$target"/"$foldername"/aqua/aqua_out/parsedjson/
    mkdir ./targets/"$target"/"$foldername"/subdomain_enum/
    #mkdir ./targets/"$target"/"$foldername"/subdomain_enum/amass/
    #mkdir ./targets/"$target"/"$foldername"/subdomain_enum/gobuster/
    mkdir ./targets/"$target"/"$foldername"/screenshots/
    #mkdir ./targets/"$target"/"$foldername"/directory_fuzzing/
    #mkdir ./targets/"$target"/"$foldername"/directory_fuzzing/gobuster/
    mkdir ./targets/"$target"/"$foldername"/scanning/
    #mkdir ./targets/"$target"/"$foldername"/scanning/nmap/
    mkdir ./targets/"$target"/"$foldername"/scanning/nuclei/
    touch ./targets/"$target"/"$foldername"/responsive-domains-80-443.txt
    touch ./targets/"$target"/"$foldername"/subdomain-takeover-results.json
    touch ./targets/"$target"/"$foldername"/alldomains.txt
    touch ./targets/"$target"/"$foldername"/temp-clean.txt
    touch ./targets/"$target"/"$foldername"/subdomains-jq.txt
    touch ./targets/"$target"/"$foldername"/"$target"-ips.txt

    excludedomains
    recon "$target"
    validation
    notify_finished
    double_check_excluded
    make_csv
    echo "${green}Scan for "$target" finished successfully${reset}"
    duration=$SECONDS
    echo "Completed in : $((duration / 60)) minutes and $((duration % 60)) seconds."
    stty sane
    tput sgr0
  fi
}
todate=$(date +"%Y-%m-%d")
totime=$(date +"%I:%M")
path=$(pwd)
foldername=$todate"-"$totime

main $@
