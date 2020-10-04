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
#         NOTES: v0.3.5
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

export GOPATH="${HOME}/go"
export PATH="${PATH}:${GOPATH}/bin"
S3_ENDPOINT="$(cat ${PWD}/backup-files/s3-endpoint.txt)"
S3_BUCKET="$(cat ${PWD}/backup-files/s3-bucket.txt)"

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

# borrowed some stuff and general idea of automated platform from lazyrecon
# https://github.com/nahamsec/lazyrecon
auquatoneThreads=8
subdomainThreads=15
subjackThreads=15
httprobeThreads=50

ssh_file="~/.ssh/id_rsa"
# Good call @1efty
CHROMIUM="${CHROMIUM:-"chromium"}"
chromiumPath="$(which $CHROMIUM)"

if [ -s ./backup-files/slack_url.txt ]; then
  slack_url=$(<./backup-files/slack_url.txt)
else
  slack_url=""
fi
if [ -s ./backup-files/bot_user_oauth_at.txt ]; then
  bot_token=$(<./backup-files/bot_user_oauth_at.txt)
else
  bot_token=""
fi
if [ -s ./backup-files/slack_channel.txt ]; then
  slack_channel=$(<./backup-files/slack_channel.txt)
else
  slack_channel=""
fi

target=""
subdomain_scan_target=""
subdomain_scan_target_file=" "
all_subdomain_scan_target_file=" "
excluded=""
function usage() {
  echo -e "Usage: ./the_hunting.sh --target <target domain> [--exclude] [excluded.domain.com,other.domain.com]\nOptions:\n  --exclude\t-\tspecify excluded subdomains\n --file\t-\tpass a newline seperated file of subdomains to scan\n --file-all\t-\tsame as --file, but uses all templates to scan\n --logo\t-\tprints a cool ass logo\n --license\t-\tprints a boring ass license" 1>&2
  exit 1
}

function excludedomains() {
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
function run_amass() {
  if [ -s ./targets/"$target"/"$foldername"/excluded.txt ]; then
    amass enum -norecursive -passive -config ./backup-files/amass_config.ini -blf ./targets/"$target"/"$foldername"/excluded.txt -dir ./targets/"$target"/"$foldername"/subdomain_enum/amass/ -oA ./targets/"$target"/"$foldername"/subdomain_enum/amass/amass-"$todate" -d "$target"
  else
    amass enum -norecursive -passive -config ./backup-files/amass_config.ini -dir ./targets/"$target"/"$foldername"/subdomain_enum/amass/ -oA ./targets/"$target"/"$foldername"/subdomain_enum/amass/amass-"$todate" -d "$target"
  fi
  #ret=$?
  #if [[ $ret -ne 0 ]] ; then
  #notify_error
  #fi
  cat ./targets/"$target"/"$foldername"/subdomain_enum/amass/amass-"$todate".txt >>./targets/"$target"/"$foldername"/alldomains.txt
}
#new amass
function run_json_amass() {
  if [ -s ./targets/"$target"/"$foldername"/excluded.txt ]; then
    amass enum -norecursive -passive -config ./backup-files/amass_config.ini -blf ./targets/"$target"/"$foldername"/excluded.txt -json ./targets/"$target"/"$foldername"/subdomain_enum/amass/amass-"$todate".json -d "$target"
  else
    amass enum -norecursive -passive -config ./backup-files/amass_config.ini -json ./targets/"$target"/"$foldername"/subdomain_enum/amass/amass-"$todate".json -d "$target"
  fi
  #ret=$?
  #if [[ $ret -ne 0 ]] ; then
  #notify_error
  #fi
  #cat ./targets/"$target"/"$foldername"/subdomain_enum/amass/amass-"$todate".txt >> ./targets/"$target"/"$foldername"/alldomains.txt
}
function run_subfinder_json() {
  subfinder -silent -config ./backup-files/subfinder.yaml -d "$target" -o ./targets/"$target"/"$foldername"/subfinder.json -oJ -nW -all
  #ret=$?
  #if [[ $ret -ne 0 ]] ; then
  #notify_error
  #fi
}
#gobuster vhost broken
function run_gobuster_vhost() {
  echo "${yellow}Running Gobuster vhost...${reset}"
  gobuster vhost -u "$target" -w ./wordlists/subdomains-top-110000.txt -a "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0" -k -o ./targets/"$target"/"$foldername"/subdomain_enum/gobuster/gobuster_vhost-"$todate".txt
  ret=$?
  if [[ $ret -ne 0 ]]; then
    notify_error
  fi
  cat ./targets/"$target"/"$foldername"/subdomain_enum/gobuster/gobuster_vhost-"$todate".txt >>./targets/"$target"/"$foldername"/alldomains.txt
  echo "${green}Gobuster vhost finished.${reset}"
}
function run_gobuster_dns() {
  echo "${yellow}Running Gobuster dns...${reset}"
  gobuster dns -d "$target" -w ./wordlists/subdomains-top-110000.txt -z -q -t "$subdomainThreads" -o ./targets/"$target"/"$foldername"/subdomain_enum/gobuster/gobuster_dns-"$todate".txt
  ret=$?
  if [[ $ret -ne 0 ]]; then
    notify_error
  fi
  cat ./targets/"$target"/"$foldername"/subdomain_enum/gobuster/gobuster_dns-"$todate".txt | awk -F ' ' '{print $2}' >>./targets/"$target"/"$foldername"/alldomains.txt
  echo "${green}Gobuster dns finished.${reset}"
}
function run_subjack() {
  echo "${yellow}Running subjack...${reset}"
  $HOME/go/bin/subjack -a -w ./targets/"$target"/"$foldername"/subdomains-jq.txt -ssl -t "$subjackThreads" -m -timeout 15 -c ./fingerprints.json  -o ./targets/"$target"/"$foldername"/subdomain-takeover-results.json -v
  ret=$?
  if [[ $ret -ne 0 ]]; then
    notify_error
  fi
  echo "${green}subjack finished.${reset}"
}
function run_httprobe() {
  echo "${yellow}Running httprobe...${reset}"
  cat ./targets/"$target"/"$foldername"/subdomains-jq.txt | httprobe -c "$httprobeThreads" >>./targets/"$target"/"$foldername"/responsive-domains-80-443.txt
  ret=$?
  if [[ $ret -ne 0 ]]; then
    notify_error
  fi
  echo "${green}httprobe finished.${reset}"
}
function run_aqua() {
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
function run_gobuster_dir() {
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
function run_dirb() {
  true
}
function run_nuclei() {
  echo "${yellow}Running Nuclei templates scan...${reset}"
  nuclei -v -json -l ./targets/"$target"/"$foldername"/responsive-domains-80-443.txt -t ./nuclei-templates/cves/ -t ./nuclei-templates/vulnerabilities/ -t ./nuclei-templates/security-misconfiguration/ -t ./deepdive/nuclei-templates/generic-detections/ -t ./deepdive/nuclei-templates/files/ -t ./deepdive/nuclei-templates/workflows/ -t ./deepdive/nuclei-templates/tokens/ -t ./deepdive/nuclei-templates/dns/ -o ./targets/"$target"/"$foldername"/scanning/nuclei/nuclei-results.json
  #  nuclei -v -json -l ./targets/"$target"/"$foldername"/aquatone_urls.txt -t ./nuclei-templates/vulnerabilities/ -o ./targets/"$target"/"$foldername"/scanning/nuclei/nuclei-vulnerabilties-results.json
  #  nuclei -v -json -l ./targets/"$target"/"$foldername"/aquatone_urls.txt -t ./nuclei-templates/security-misconfiguration/ -o ./targets/"$target"/"$foldername"/scanning/nuclei/nuclei-security-misconfigurations-results.json
  echo "${green}Nuclei stock cve templates scan finished...${reset}"
}
function subdomain_scanning() {
  nuclei -v -json -l "$subdomain_scan_target_file" -t ./nuclei-templates/cves/ -t ./nuclei-templates/vulnerabilities/ -t ./nuclei-templates/security-misconfiguration/ -t ./nuclei-templates/generic-detections/ -t ./nuclei-templates/files/ -t ./nuclei-templates/workflows/ -t ./nuclei-templates/tokens/ -t ./nuclei-templates/dns/ -o ./deepdive/"$todate"-"$totime"-nuclei-vulns.json
}
function all_subdomain_scanning() {
  nuclei -v -json -l "$all_subdomain_scan_target_file" -t ./nuclei-templates/ -o ./deepdive/"$todate"-"$totime"-nuclei-vulns.json
}
function run_nmap() {
  true
}
# zap stuff
function start_zap() {
  file="$subdomain_scan_target_file"
  echo "${yellow}Starting zap instance...${reset}"
  echo "${red} Just kidding! Working on it though.${reset}"
  ./home/root/zap/zap.sh -daemon -port 8090 -config api.key=12345 &>/dev/null &
  echo "${green}zap started!${reset}"
}
function stop_zap() {
  curl -s "http://localhost:8090/JSON/core/action/shutdown/?apikey=12345"
}
function zap_spider() {
  file="$subdomain_scan_target_file"
  for sf in $file; do
    curl -s "http://localhost:8090/JSON/spider/action/scan/?apikey=12345&zapapiformat=JSON&formMethod=GET&url=""$sf" | jq .
  # get spider status, check it every 30 seconds until value is 100
    while true; do
      value=$(curl -s "http://localhost:8090/JSON/spider/view/status/?apikey=12345" | jq -r ".status")
      if [ value = "100" ]; then
        break
      fi
      sleep 15
    done
  done
}
# notifications slack
function notify_finished() {
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
function notify_subdomain_scan() {
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
function notify_error() {
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

function send_file() {
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
function undo_amass_config() {
  if [ -s ./amass_config.bak ]; then
    mv ./amass_config.bak ./amass_config.ini
    #rm ./amass_config.bak
  fi
}

function undo_subdomain_file() {
  if [ -s ./deepdive/subdomain.txt ]; then
    rm ./deepdive/subdomain.txt
    touch ./deepdive/subdomain.txt
  fi
}

function make_files() {
  paste -s -d ',' ./targets/"$target"/"$foldername"/responsive-domains-80-443.txt >./s3-booty/"$target"-csv.txt
  cp ./targets/"$target"/"$foldername"/responsive-domains-80-443.txt ./s3-booty/"$target"-newline.txt
}
function read_direct_wordlist() {
  cat ./targets/"$target"/"$foldername"/aqua/aqua_out/aquatone_urls.txt
}
function uniq_subdomains() {
  uniq -i ./targets/"$target"/"$foldername"/aqua/aqua_out/aquatone_urls.txt >>./targets/"$target"/"$foldername"/uniqdomains1.txt
}
function double_check_excluded() {
  if [ -s ./targets/"$target"/"$foldername"/excluded.txt ]; then
    grep -vFf ./targets/"$target"/"$foldername"/excluded.txt ./targets/"$target"/"$foldername"/responsive-domains-80-443.txt >./targets/"$target"/"$foldername"/2responsive-domains-80-443.txt
    rm ./targets/"$target"/"$foldername"/responsive-domains-80-443.txt
    mv ./targets/"$target"/"$foldername"/2responsive-domains-80-443.txt ./targets/"$target"/"$foldername"/responsive-domains-80-443.txt
  fi
}
function parse_json() {
  # ips
  cat ./targets/"$target"/"$foldername"/subfinder.json | jq -r '.ip' >./targets/"$target"/"$foldername"/"$target"-ips.txt
  #domain names
  cat ./targets/"$target"/"$foldername"/subfinder.json | jq -r '.host' >./targets/"$target"/"$foldername"/subdomains-jq.txt
}

# doctl hax
function create_image() {
  image_id=$(doctl compute image list | awk '/the_hunting/ {print $1}' | head -n1)
  if [ -n "$image_id" ]; then
    size="s-1vcpu-1gb"
    region="sfo2"
    if [ -z $set_domain ]; then
      domain=$set_domain
    else
      domain=""
    fi
    doctl compute droplet create the-hunting --image $image_id --size $size --region $region --ssh-keys $ssh_key $domain
  else
    echo "No snapshots have been created. Have you run make lately?"
    exit
  fi
}
function connect_image() {
  doctl compute ssh the-hunting
}
function remove_image() {
  doctl compute droplet delete the-hunting
}
# S3fs-fuse
function upload_s3_recon() {
  if [[ -z "$S3_BUCKET" ]]; then
    true
  else
    aws s3 cp --recursive ./targets/"$target"/"$foldername" s3://"$S3_BUCKET"/targets/"$target"/"$foldername" --profile the_hunting
    aws s3 cp --recursive ./s3-booty/ s3://$S3_BUCKET/s3-booty/ --profile the_hunting
  fi
}
function upload_s3_scan() {
  if [[ -z "$S3_BUCKET" ]]; then
    true
  else
    aws s3 cp --recursive ./deepdive/ s3://"$S3_BUCKET"/deepdive/"$target"/"$foldername" --profile the_hunting
  fi
}
# children
function subdomain_enum() {
  echo "${yellow}Running subdomain enum...${reset}"
  #Amass https://github.com/OWASP/Amass
  #run_amass
  #run_json_amass
  run_subfinder_json
  parse_json
  echo "${green}subdomain recon finished.${reset}"
  #Gobuster trying to make them run at same time
  #run_gobuster_vhost
  #run_gobuster_dns
}
function sub_takeover() {
  run_subjack
}
function target_valid() {
  run_httprobe
}
function webapp_valid() {
  run_aqua
}
function fuzz_em() {
  #run_gobuster_dir
  run_dirb
}
function webapp_scan() {
  run_nuclei
}
function port_scan() {
  run_nmap
}
# main func's
function recon() {
  subdomain_enum
  sub_takeover
}
function validation() {
  target_valid
  webapp_valid
  uniq_subdomains
}
function scanning() {
  port_scan
  fuzz_em
  webapp_scan
}
# graphic opening stuff
function logo() {
  base64 -d <<<"4paI4paI4paI4paI4paI4paI4paI4paI4pWX4paI4paI4pWXICDilojilojilZfilojilojilojilojilojilojilojilZcgICAgICAgIOKWiOKWiOKVlyAg4paI4paI4pWX4paI4paI4pWXICAg4paI4paI4pWX4paI4paI4paI4pWXICAg4paI4paI4pWX4paI4paI4paI4paI4paI4paI4paI4paI4pWX4paI4paI4pWX4paI4paI4paI4pWXICAg4paI4paI4pWXIOKWiOKWiOKWiOKWiOKWiOKWiOKVlyAgICDilojilojilojilojilojilojilojilZfilojilojilZcgIOKWiOKWiOKVlwrilZrilZDilZDilojilojilZTilZDilZDilZ3ilojilojilZEgIOKWiOKWiOKVkeKWiOKWiOKVlOKVkOKVkOKVkOKVkOKVnSAgICAgICAg4paI4paI4pWRICDilojilojilZHilojilojilZEgICDilojilojilZHilojilojilojilojilZcgIOKWiOKWiOKVkeKVmuKVkOKVkOKWiOKWiOKVlOKVkOKVkOKVneKWiOKWiOKVkeKWiOKWiOKWiOKWiOKVlyAg4paI4paI4pWR4paI4paI4pWU4pWQ4pWQ4pWQ4pWQ4pWdICAgIOKWiOKWiOKVlOKVkOKVkOKVkOKVkOKVneKWiOKWiOKVkSAg4paI4paI4pWRCiAgIOKWiOKWiOKVkSAgIOKWiOKWiOKWiOKWiOKWiOKWiOKWiOKVkeKWiOKWiOKWiOKWiOKWiOKVlyAgICAgICAgICDilojilojilojilojilojilojilojilZHilojilojilZEgICDilojilojilZHilojilojilZTilojilojilZcg4paI4paI4pWRICAg4paI4paI4pWRICAg4paI4paI4pWR4paI4paI4pWU4paI4paI4pWXIOKWiOKWiOKVkeKWiOKWiOKVkSAg4paI4paI4paI4pWXICAg4paI4paI4paI4paI4paI4paI4paI4pWX4paI4paI4paI4paI4paI4paI4paI4pWRCiAgIOKWiOKWiOKVkSAgIOKWiOKWiOKVlOKVkOKVkOKWiOKWiOKVkeKWiOKWiOKVlOKVkOKVkOKVnSAgICAgICAgICDilojilojilZTilZDilZDilojilojilZHilojilojilZEgICDilojilojilZHilojilojilZHilZrilojilojilZfilojilojilZEgICDilojilojilZEgICDilojilojilZHilojilojilZHilZrilojilojilZfilojilojilZHilojilojilZEgICDilojilojilZEgICDilZrilZDilZDilZDilZDilojilojilZHilojilojilZTilZDilZDilojilojilZEKICAg4paI4paI4pWRICAg4paI4paI4pWRICDilojilojilZHilojilojilojilojilojilojilojilZfilojilojilojilojilojilojilojilZfilojilojilZEgIOKWiOKWiOKVkeKVmuKWiOKWiOKWiOKWiOKWiOKWiOKVlOKVneKWiOKWiOKVkSDilZrilojilojilojilojilZEgICDilojilojilZEgICDilojilojilZHilojilojilZEg4pWa4paI4paI4paI4paI4pWR4pWa4paI4paI4paI4paI4paI4paI4pWU4pWd4paI4paI4pWX4paI4paI4paI4paI4paI4paI4paI4pWR4paI4paI4pWRICDilojilojilZEKICAg4pWa4pWQ4pWdICAg4pWa4pWQ4pWdICDilZrilZDilZ3ilZrilZDilZDilZDilZDilZDilZDilZ3ilZrilZDilZDilZDilZDilZDilZDilZ3ilZrilZDilZ0gIOKVmuKVkOKVnSDilZrilZDilZDilZDilZDilZDilZ0g4pWa4pWQ4pWdICDilZrilZDilZDilZDilZ0gICDilZrilZDilZ0gICDilZrilZDilZ3ilZrilZDilZ0gIOKVmuKVkOKVkOKVkOKVnSDilZrilZDilZDilZDilZDilZDilZ0g4pWa4pWQ4pWd4pWa4pWQ4pWQ4pWQ4pWQ4pWQ4pWQ4pWd4pWa4pWQ4pWdICDilZrilZDilZ0="
}
function credits() {
  print_line
  base64 -d <<<"Q3JlZGl0czogVGhhbmtzIHRvIGh0dHBzOi8vZ2l0aHViLmNvbS9PSiBodHRwczovL2dpdGh1Yi5jb20vT1dBU1AgaHR0cHM6Ly9naXRodWIuY29tL2hhY2NlcgpodHRwczovL2dpdGh1Yi5jb20vdG9tbm9tbm9tIGh0dHBzOi8vZ2l0aHViLmNvbS9taWNoZW5yaWtzZW4gJiBUaGUgRGFyayBSYXZlciBmb3IgdGhlaXIKd29yayBvbiB0aGUgcHJvZ3JhbXMgdGhhdCB3ZW50IGludG8gdGhlIG1ha2luZyBvZiB0aGVfaHVudGluZy5zaC4="
  echo " "
  print_line
}
function licensing_info() {
  base64 -d <<<"dGhlX2h1bnRpbmcgQ29weXJpZ2h0IChDKSAyMDIwICBAaW5jcmVkaW5jb21wClRoaXMgcHJvZ3JhbSBjb21lcyB3aXRoIEFCU09MVVRFTFkgTk8gV0FSUkFOVFk7IGZvciBkZXRhaWxzIGNhbGwgYC4vdGhlX2h1bnRpbmcuc2ggLWxpY2Vuc2VgLgpUaGlzIGlzIGZyZWUgc29mdHdhcmUsIGFuZCB5b3UgYXJlIHdlbGNvbWUgdG8gcmVkaXN0cmlidXRlIGl0IHVuZGVyIGNlcnRhaW4gCmNvbmRpdGlvbnM7IHR5cGUgYC4vdGhlX2h1bnRpbmcuc2ggLWxpY2Vuc2VgIGZvciBkZXRhaWxzLg=="
  echo " "
}
function print_line() {
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  echo " "
}
function open_program() {
  logo
  echo " "
  credits
  licensing_info
  print_line
}
function get_scan_targets() {
  #   set -f
  #   IFS=","
  #   subdomain_scan_target+=("$2")
  #   unset IFS
  #   if [ -s ./deepdive/subdomain.txt ]; then
  #     mv ./deepdive/subdomain.txt ./deepdive/lastscan.txt
  #   fi
  #   IFS=$'\n'
  #   for u in "${subdomain_scan_target[@]}"; do
  #     printf "%s\n" "$u" >>./deepdive/subdomain.txt
  #   done
  #   unset IFS
  #   subdomain_scan_target_file="./deepdive/subdomain.txt"
  true
}
function subdomain_option() {
  clear
  open_program
#  if [ ! -d ./deepdive ]; then
#    mkdir ./deepdive
#  fi
  touch ./deepdive/"$todate"-"$totime"-nuclei-vulns.json
  if [[ "$all_subdomain_scan_target_file" != " "]]; then
    all_subdomain_scanning "$all_subdomain_scan_target_file"
  elif [[ "$subdomain_scan_target" != " " ]]; then
    subdomain_scanning "$subdomain_scan_target_file"
  fi
  notify_subdomain_scan
  send_file
  undo_subdomain_file
  duration=$SECONDS
  echo "Completed in : $((duration / 60)) minutes and $((duration % 60)) seconds."
  stty sane
  tput sgr0
}

function credits() {
  print_line
  base64 -d <<<"ICAgQ3JlZGl0czogVGhhbmtzIHRvIGh0dHBzOi8vZ2l0aHViLmNvbS9PSiBodHRwczovL2dpdGh1Yi5jb20vT1dBU1AgaHR0cHM6Ly9naXRodWIuY29tL2hhY2NlcgogICBodHRwczovL2dpdGh1Yi5jb20vdG9tbm9tbm9tIGh0dHBzOi8vZ2l0aHViLmNvbS9taWNoZW5yaWtzZW4gJiBUaGUgRGFyayBSYXZlciBmb3IgdGhlaXIKICAgd29yayBvbiB0aGUgcHJvZ3JhbXMgdGhhdCB3ZW50IGludG8gdGhlIG1ha2luZyBvZiB0aGVfaHVudGluZy5zaC4="
  echo " "
  print_line
}

function licensing_info() {
  base64 -d <<<"CXRoZV9odW50aW5nIENvcHlyaWdodCAoQykgMjAyMCAgQGluY3JlZGluY29tcAoJVGhpcyBwcm9ncmFtIGNvbWVzIHdpdGggQUJTT0xVVEVMWSBOTyBXQVJSQU5UWTsgZm9yIGRldGFpbHMgY2FsbCBgLi90aGVfaHVudGluZy5zaCAtbGljZW5zZScuCglUaGlzIGlzIGZyZWUgc29mdHdhcmUsIGFuZCB5b3UgYXJlIHdlbGNvbWUgdG8gcmVkaXN0cmlidXRlIGl0LgoJdW5kZXIgY2VydGFpbiBjb25kaXRpb25zOyB0eXBlIGAuL3RoZV9odW50aW5nLnNoIC1saWNlbnNlJyBmb3IgZGV0YWlscy4="
  echo " "
}

function print_line() {
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  echo " "
}

function open_program() {
  logo
  echo " "
  credits
  licensing_info
  print_line
}

function parse_args() {
  while [[ $1 ]]; do
    echo "Handling [$1]..."
    case "$1" in
    --target)
      target="$2"
      shift
      shift
      ;;
    --exclude)
      excluded="$2"
      shift
      shift
      ;;
    #maybe this was breaking this from how hacky it is...
    --scan)
      subdomain_scan_target="$2"
      shift
      shift
      ;;
    --file)
      subdomain_scan_target_file="$2"
      shift
      shift
      ;;
    --file-all)
      all_subdomain_scan_target_file="$2"
      shift
      shift
      ;;
    --install-pr)
      ./install.sh --pre_reqs
      echo "Pre-requirements installed"
      exit
      ;;
    --install-all)
      ./install.sh --install
      echo "Everything installed"
      exit
      ;;
    --create)
      ssh_key="$2"
      create_image "$ssh_key"
      exit
      ;;
    --connect)
      connect_image
      exit
      ;;
    --remove)
      remove_image
      exit
      ;;
    --logo)
      open_program
      exit
      ;;
    --license)
      less ./LICENSE
      exit
      ;;
    *)
      echo "Error: Unknown option: $1" >&2
      usage
      exit 1
      ;;
    esac
  done
}

# main
function main() {

  # parse CLI arguments
  parse_args "$@"

  # exit if certain variables are not set
  if [[ -z "$target" ]] && [[ -z ${subdomain_scan_target[*]} ]] && [[ -z "$subdomain_scan_target_file" ]] && [[ -z "$all_subdomain_scan_target_file" ]]; then
    usage
    exit 1
  fi

  if [[ -z "$target" ]]; then
    subdomain_option
    upload_s3_scan
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
    make_files
    upload_s3_recon
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

main "$@"
