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
#         NOTES: v0.4.0
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

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

auquatoneThreads=4
subdomainThreads=15
subjackThreads=15
httprobeThreads=50
droplet_size="s-1vcpu-1gb"
droplet_region="sfo2"

random_api=$(openssl rand -hex 8)
# discover which chromium to use
# if first guess doesn't exist, try an alternative
chromiumPath="$(which chromium 2>/dev/null || which chromium-browser)"

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
if [ -s ./backup-files/s3-bucket.txt ]; then
  S3_BUCKET=$(<./backup-files/s3-bucket.txt)
else
  S3_BUCKET=""
fi
if [ -s ./backup-files/custom-header.txt ]; then
  custom_header=$(<./backup-files/custom-header.txt)
else
  custom_header=""
fi

target=""
excluded=""
subdomain_scan_target_file=""
all_subdomain_scan_target_file=""
function usage() {
  echo -e "Usage: ./the_hunting.sh --target <target domain> [--exclude] [excluded.domain.com,other.domain.com]\nOptions:\n  --exclude\t-\tspecify excluded subdomains\n  --file\t-\tpass a newline seperated file of subdomains to scan\n  --file-all\t-\tsame as --file, but uses all templates to scan\n  --spider\t-\tspider a list of urls with owaspzap\n  --create\t-\tcreate a droplet with your snapshot from make build\n  --connect\t-\tbasic ssh tunnel\n  --tmux\t-\tcreate a tmux session (recommended)\n  --rmux\t-\treconnect to main tmux session\n  --remove\t-\tdelete your hunting droplet\n  --logo\t-\tprints a cool ass logo\n  --license\t-\tprints a boring ass license\n  --help\t-\tprints this help\n" 1>&2
  exit 1
}
function set_header() {
  if [ -z "$custom_header" ]; then
    echo "No custom header has been set"
    echo -n "would you like to set a custom header for active scans? [yYnN]"
    read ans
    case "$ans" in
      [yY])
        echo -n "What would you like your custom header to say?"
        read custom_header
        echo "$custom_header" > ./backup-files/custom_header.txt
        return
        ;;
      [nN])
        echo "No custom header has been set"
        return
        ;;
      *)
        echo "No comprendo mi amigo! Volver a intentar."
        ;;
      esac
  else
    true
  fi
}
function excludedomains() {
  echo "Excluding domains (if you set them with -e)..."
  if [ -z "$excluded" ]; then
    echo "No subdomains have been exluded"
  else
    touch ./targets/"$target_dir"/"$foldername"/excluded.txt
    echo $excluded | tr -s ',' '\n' >>./targets/"$target_dir"/"$foldername"/excluded.txt
    echo "${green}Subdomains that have been excluded from discovery:${reset}"
    cat ./targets/"$target_dir"/"$foldername"/excluded.txt
  fi
}
# parents
function run_amass() {
  if [ -s ./targets/"$target_dir"/"$foldername"/excluded.txt ]; then
    amass enum -norecursive -passive -nolocaldb -config ./backup-files/amass_config.ini -blf ./targets/"$target_dir"/"$foldername"/excluded.txt -dir ./targets/"$target_dir"/"$foldername"/subdomain_enum/amass/ -oA ./targets/"$target_dir"/"$foldername"/subdomain_enum/amass/amass-"$todate" -d "$target"
  else
    amass enum -norecursive -passive -nolocaldb -config ./backup-files/amass_config.ini -dir ./targets/"$target_dir"/"$foldername"/subdomain_enum/amass/ -oA ./targets/"$target_dir"/"$foldername"/subdomain_enum/amass/amass-"$todate" -d "$target"
  fi
  cp ./targets/"$target_dir"/"$foldername"/subdomain_enum/amass/amass-"$todate".txt ./targets/"$target_dir"/"$foldername"/alldomains.txt
}
#new amass
function run_json_amass() {
  if [ -s ./targets/"$target_dir"/"$foldername"/excluded.txt ]; then
    amass enum -norecursive -passive -nolocaldb -config ./backup-files/amass_config.ini -blf ./targets/"$target_dir"/"$foldername"/excluded.txt -json ./targets/"$target_dir"/"$foldername"/subdomain_enum/amass/amass-"$todate".json -d "$target"
  else
    amass enum -norecursive -passive -nolocaldb -config ./backup-files/amass_config.ini -json ./targets/"$target_dir"/"$foldername"/subdomain_enum/amass/amass-"$todate".json -d "$target"
  fi
  #cat ./targets/"$target_dir"/"$foldername"/subdomain_enum/amass/amass-"$todate".txt >> ./targets/"$target_dir"/"$foldername"/alldomains.txt
}
function run_subfinder_json() {
  subfinder -config ./backup-files/subfinder.yaml -d "$target" -o ./targets/"$target_dir"/"$foldername"/subfinder.json -oJ -nW -all
  #ret=$?
  #if [[ $ret -ne 0 ]] ; then
  #notify_error
  #fi
}
#gobuster vhost broken
function run_gobuster_vhost() {
  echo "${yellow}Running Gobuster vhost...${reset}"
  gobuster vhost -u "$target" -w ./wordlists/subdomains-top-110000.txt -a "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0" -k -o ./targets/"$target_dir"/"$foldername"/subdomain_enum/gobuster/gobuster_vhost-"$todate".txt
  cat ./targets/"$target_dir"/"$foldername"/subdomain_enum/gobuster/gobuster_vhost-"$todate".txt >>./targets/"$target_dir"/"$foldername"/alldomains.txt
  echo "${green}Gobuster vhost finished.${reset}"
}
function run_gobuster_dns() {
  echo "${yellow}Running Gobuster dns...${reset}"
  gobuster dns -d "$target_dir" -w ./wordlists/subdomains-top-110000.txt -z -q -t "$subdomainThreads" -o ./targets/"$target_dir"/"$foldername"/subdomain_enum/gobuster/gobuster_dns-"$todate".txt
  cat ./targets/"$target_dir"/"$foldername"/subdomain_enum/gobuster/gobuster_dns-"$todate".txt | awk -F ' ' '{print $2}' >>./targets/"$target_dir"/"$foldername"/alldomains.txt
  echo "${green}Gobuster dns finished.${reset}"
}
function run_subjack() {
  echo "${yellow}Running subjack...${reset}"
  if [ -s ./targets/"$target_dir"/"$foldername"/subdomains-jq.txt ]; then
    $HOME/go/bin/subjack -a -w ./targets/"$target_dir"/"$foldername"/subdomains-jq.txt -ssl -t "$subjackThreads" -m -timeout 15 -c "./files/conf/fingerprints.json" -o ./targets/"$target_dir"/"$foldername"/subdomain-takeover-results.json -v
  else
    $HOME/go/bin/subjack -a -w ./targets/"$target_dir"/"$foldername"/alldomains.txt -ssl -t "$subjackThreads" -m -timeout 15 -c "./files/conf/fingerprints.json" -o ./targets/"$target_dir"/"$foldername"/subdomain-takeover-results.json -v
  fi
  echo "${green}subjack finished.${reset}"
}
function run_httprobe() {
  echo "${yellow}Running httprobe...${reset}"
  if [ -s ./targets/"$target_dir"/"$foldername"/subdomains-jq.txt ]; then
    cat ./targets/"$target_dir"/"$foldername"/subdomains-jq.txt | httprobe -c "$httprobeThreads" >>./targets/"$target_dir"/"$foldername"/responsive-domains-80-443.txt
  else
    cat ./targets/"$target_dir"/"$foldername"/subdomain_enum/amass/amass-"$todate".txt | httprobe -c "$httprobeThreads" >>./targets/"$target_dir"/"$foldername"/responsive-domains-80-443.txt
  fi
  cp ./targets/"$target_dir"/"$foldername"/subdomain_enum/amass/amass-"$todate".txt ./s3-booty/"$target_dir"-newline.txt
  echo "${green}httprobe finished.${reset}"
}
function run_aqua() {
  echo "${yellow}Running Aquatone...${reset}"
  cat ./targets/"$target_dir"/"$foldername"/responsive-domains-80-443.txt | aquatone -threads $auquatoneThreads -chrome-path $chromiumPath -out ./targets/"$target_dir"/"$foldername"/aqua/aqua_out
  ret=$?
#  cp ./targets/"$target_dir"/"$foldername"/aqua/aqua_out/aquatone_report.html ./targets/"$target_dir"/"$foldername"/aquatone_report.html
#  cp ./targets/"$target_dir"/"$foldername"/aqua/aqua_out/aquatone_urls.txt ./targets/"$target_dir"/"$foldername"/aquatone_urls.txt
  echo "${green}Aquatone finished...${reset}"
}
function run_gobuster_dir() {
  #crazy headed and dangerous, untested really.. dont know what happens with output
  echo "${yellow}Running Gobuster dir...${reset}"
  read_direct_wordlist | parallel --results ./targets/"$target_dir"/"$foldername"/directory_fuzzing/gobuster/ gobuster dir -z -q -u {} -w ./wordlists/directory-list.txt -f -k -e -r -a "Mozilla/5.0 \(X11\; Ubuntu\; Linux x86_64\; rv\:80.0\) Gecko/20100101 Firefox/80.0"
  ret=$?
  cat ./targets/"$target_dir"/"$foldername"/directory_fuzzing/gobuster/1/"$target_dir"/stdout | awk -F ' ' '{print $1}' >>./targets/"$target_dir"/"$foldername"/live_paths.txt
  echo "${green}Gobuster dir finished...${reset}"
}
function run_dirb() {
  true
}
function run_nuclei() {
  echo "${yellow}Running Nuclei templates scan...${reset}"
  nuclei -json -json-requests -pbar -l ./targets/"$target_dir"/"$foldername"/responsive-domains-80-443.txt -t ./nuclei-templates/cves/ -t ./nuclei-templates/vulnerabilities/ -t ./nuclei-templates/security-misconfiguration/ -t ./nuclei-templates/generic-detections/ -t ./nuclei-templates/files/ -t ./nuclei-templates/workflows/ -t ./nuclei-templates/tokens/ -t ./nuclei-templates/dns/ -o ./targets/"$target_dir"/"$foldername"/scanning/nuclei/nuclei-results.json
  #  nuclei -v -json -l ./targets/"$target_dir"/"$foldername"/aquatone_urls.txt -t ./nuclei-templates/vulnerabilities/ -o ./targets/"$target_dir"/"$foldername"/scanning/nuclei/nuclei-vulnerabilties-results.json
  #  nuclei -v -json -l ./targets/"$target_dir"/"$foldername"/aquatone_urls.txt -t ./nuclei-templates/security-misconfiguration/ -o ./targets/"$target_dir"/"$foldername"/scanning/nuclei/nuclei-security-misconfigurations-results.json
  echo "${green}Nuclei stock cve templates scan finished...${reset}"
}
function subdomain_scanning() {
  if [ -n "$custom_header" ]; then
    nuclei -json -json-requests -H "$custom_header" -l "$subdomain_scan_target_file" -t ./nuclei-templates/cves/ -t ./nuclei-templates/vulnerabilities/ -t ./nuclei-templates/security-misconfiguration/ -t ./nuclei-templates/generic-detections/ -t ./nuclei-templates/files/ -t ./nuclei-templates/workflows/ -t ./nuclei-templates/tokens/ -t ./nuclei-templates/dns/ -o ./s3-booty/nuclei/"$todate"-"$totime"-nuclei-vulns.json
  else
    nuclei -json -json-requests -l "$subdomain_scan_target_file" -t ./nuclei-templates/cves/ -t ./nuclei-templates/vulnerabilities/ -t ./nuclei-templates/security-misconfiguration/ -t ./nuclei-templates/generic-detections/ -t ./nuclei-templates/files/ -t ./nuclei-templates/workflows/ -t ./nuclei-templates/tokens/ -t ./nuclei-templates/dns/ -o ./s3-booty/nuclei/"$todate"-"$totime"-nuclei-vulns.json
  fi
}
function all_subdomain_scanning() {
  if [ -z "$custom_header" ]; then
    nuclei -json -json-requests -l "$all_subdomain_scan_target_file" -t ./nuclei-templates/ -o ./s3-booty/"$todate"-"$totime"-nuclei-vulns.json
  else
    #custom header
    nuclei -json -json-requests -H "$custom_header" -l "$all_subdomain_scan_target_file" -t ./nuclei-templates/ -o ./s3-booty/"$todate"-"$totime"-nuclei-vulns.json
  fi
}
function run_nmap() {
  true
}
# zap stuff
function start_zap() {
  file="$subdomain_scan_target_file"
  echo "${yellow}Starting zap instance...${reset}"
  echo "${red} Just kidding! Working on it though.${reset}"
  ./home/"$USER"/zap/zap.sh -daemon -port 8090 -config api.key="$random_api" &>/dev/null &
  echo "${green}zap started!${reset}"
}
function stop_zap() {
  curl -s "http://localhost:8090/JSON/core/action/shutdown/?apikey=""$random_api"
}
function zap_spider() {
  file="$zap_spider_target_file"
  for sf in $file; do
    curl -s "http://localhost:8090/JSON/spider/action/scan/?apikey=""$random_api""&zapapiformat=JSON&formMethod=GET&url=""$sf" | jq .
    # get spider status, check it every 30 seconds until value is 100
    while true; do
      value=$(curl -s "http://localhost:8090/JSON/spider/view/status/?apikey=""$random_api" | jq -r ".status")
      if [ "$value" = "100" ]; then
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
    if [ -s ./targets/"$target_dir"/"$foldername"/subdomains-jq.txt ]; then
      num_of_subd=$(wc <./targets/"$target_dir"/"$foldername"/subdomains-jq.txt -l)
      data1=''{\"text\":\"Your\ scan\ of\ "'"$target"'"\ is\ complete!\ \`the\_hunting.sh\`\ found\ "'"$num_of_subd"'"\ responsive\ subdomains\ to\ scan.\"}''
      curl -X POST -H 'Content-type: application/json' --data "$data1" https://hooks.slack.com/services/"$slack_url"
    else
      num_of_subd=$(wc <./targets/"$target_dir"/"$foldername"/alldomains.txt -l)
      data1=''{\"text\":\"Your\ scan\ of\ "'"$target"'"\ is\ complete!\ \`the\_hunting.sh\`\ found\ "'"$num_of_subd"'"\ responsive\ subdomains\ to\ scan.\"}''
      curl -X POST -H 'Content-type: application/json' --data "$data1" https://hooks.slack.com/services/"$slack_url"
    fi
    echo "${green}Notification sent!${reset}"
  fi
}
function notify_subdomain_scan() {
  if [ -z "$slack_url" ]; then
    echo "${red}Notifications not set up. Add your slack url to ./slack_url.txt${reset}"
  else
    echo "${yellow}Notification being generated and sent...${reset}"
#    if [ -s ./s3-booty/nuclei-vulns.json ]; then
      num_of_vuln=$(wc <./s3-booty/nuclei/"$todate"-"$totime"-nuclei-vulns.json -l)
      data1=''{\"text\":\"Your\ subdomain\ scan\ is\ complete!\ \`the\_hunting.sh\`\ found\ "'"$num_of_vuln"'"\ vulnerabilities.\"}''
      curl -X POST -H 'Content-type: application/json' --data "$data1" https://hooks.slack.com/services/"$slack_url"
#    else
#      num_of_vuln=$(wc <./s3-booty/"$target_dir"-"$todate"-"$totime"-nuclei-vulns.json -l)
#      data1=''{\"text\":\"Your\ subdomain\ scan\ is\ complete!\ \`the\_hunting.sh\`\ found\ "'"$num_of_vuln"'"\ vulnerabilities.\"}''
#      curl -X POST -H 'Content-type: application/json' --data "$data1" https://hooks.slack.com/services/"$slack_url"
#    fi
  fi
  echo "${green}Notification sent!${reset}"
}
function notify_spider_finished() {
  if [ -z "$slack_url" ]; then
    echo "${red}Notifications not set up. Add your slack url to ./slack_url.txt${reset}"
  else
    echo "${yellow}Notification being generated and sent...${reset}"
    data1=''{\"text\":\"Your\ spider\ of\ "'"$zap_spider_target_file"'"\ is\ complete!\"}''
    curl -X POST -H 'Content-type: application/json' --data "$data1" https://hooks.slack.com/services/"$slack_url"
    echo "${green}Notification sent!${reset}"
  fi
}
function notify_error() {
  if [ -z "$slack_url" ]; then
    echo "${red}Notifications not set up. Add your slack url to ./slack_url.txt${reset}"
  else
    echo "${yellow}Error notification being generated and sent...${reset}"
    num_of_subd=$(wc <./targets/"$target_dir"/"$foldername"/responsive-domains-80-443.txt -l)
    data1=''{\"text\":\"There\ was\ an\ error\ on\ your\ scan\ of\ "'"$target"'"!\ Check\ your\ instance\ of\ \`the\_hunting.sh\`\.\ \`the\_hunting.sh\`\ still\ found\ "'"$num_of_subd"'"\ responsive\ subdomains\ to\ scan.\"}''
    curl -X POST -H 'Content-type: application/json' --data "$data1" https://hooks.slack.com/services/"$slack_url"
    echo "${green}Notification sent!${reset}"
  fi
}
function send_file() {
  if [ -z "$slack_url" ]; then
    echo "${red}Notifications not set up. Add your slack url to ./slack_url.txt${reset}"
  else
    if [ -z "$slack_channel" ] && [ -z "$bot_token" ] && [ -z "$bot_user_oauth_at" ] && [ -s ./s3-booty/"$target_dir"-"$todate"-"$totime"-nuclei-vulns.json ]; then
      echo "${red}Notifications not set up."
      echo "${red}Add your slack channel to ./slack_channel.txt"
      echo "${red}Add your slack bot user oauth token to ./bot_user_oauth_at.txt${reset}"
    else
      echo "${yellow}File being sent...${reset}"
      curl -F file=@./s3-booty/"$todate"-"$totime"-nuclei-vulns.json -F "initial_comment=Vulns from your most recent scan." -F channels="$slack_channel" -H "Authorization: Bearer ${bot_token}" https://slack.com/api/files.upload
      echo "${green}File sent!${reset}"
    fi
  fi
}
function read_direct_wordlist() {
  cat ./targets/"$target_dir"/"$foldername"/aqua/aqua_out/aquatone_urls.txt
}
function uniq_subdomains() {
  uniq -i ./targets/"$target_dir"/"$foldername"/aqua/aqua_out/aquatone_urls.txt >>./targets/"$target_dir"/"$foldername"/uniqdomains1.txt
}
function double_check_excluded() {
  if [ -s ./targets/"$target_dir"/"$foldername"/excluded.txt ]; then
    if [ -s ./targets/"$target_dir"/"$foldername"/responsive-domains-80-443.txt ]; then
      grep -vFf ./targets/"$target_dir"/"$foldername"/excluded.txt ./targets/"$target_dir"/"$foldername"/responsive-domains-80-443.txt >./targets/"$target_dir"/"$foldername"/2responsive-domains-80-443.txt
      mv ./targets/"$target_dir"/"$foldername"/2responsive-domains-80-443.txt ./targets/"$target_dir"/"$foldername"/responsive-domains-80-443.txt
    else
      grep -vFf ./targets/"$target_dir"/"$foldername"/excluded.txt ./targets/"$target_dir"/"$foldername"/alldomains.txt >./targets/"$target_dir"/"$foldername"/2alldomains.txt
      mv ./targets/"$target_dir"/"$foldername"/2alldomains.txt ./targets/"$target_dir"/"$foldername"/alldomains.txt
    fi
  fi
}
function parse_json() {
  if [ -s "./targets/"$target_dir"/"$foldername"/subfinder.json" ]; then
    # ips
    cat ./targets/"$target_dir"/"$foldername"/subfinder.json | jq -r '.ip' >./targets/"$target_dir"/"$foldername"/"$target_dir"-ips.txt
    #domain names
    cat ./targets/"$target_dir"/"$foldername"/subfinder.json | jq -r '.host' >./targets/"$target_dir"/"$foldername"/subdomains-jq.txt
  fi
}
# doctl hax
function create_image() {
  image_id=$(doctl compute image list | awk '/the_hunting/ {print $1}' | head -n1)
  if [ -z "$image_id" ]; then
    echo "No snapshots have been created. Have you run make lately?"
    exit
  else
    if [ -z "$set_domain" ]; then
      domain="$set_domain"
      doctl compute droplet create the-hunting --image $image_id --size $droplet_size --region $droplet_region --ssh-keys $ssh_key $hunting_fingerprint $domain
    else
      doctl compute droplet create the-hunting --image $image_id --size $droplet_size --region $droplet_region --ssh-keys $ssh_key $hunting_fingerprint
    fi

  fi
}
function connect_image() {
   doctl compute ssh the-hunting
}
function remove_image() {
   doctl compute droplet delete the-hunting
}
function tmux_image() {
  #image_id=$(doctl compute image list | awk '/the_hunting/ {print $1}' | head -n1)
  image_ip=$(doctl compute droplet list --format "Name,PublicIPv4" | awk '/the-hunting/ {print $2}' | head -n1)
  #response=$(ssh -o StrictHostKeyChecking=no root@"$image_ip" 'tmux list-session' 2>&1)
  ssh -o StrictHostKeyChecking=no -t root@"$image_ip" 'tmux new-session -t hunting'
}
function reconnect_tmux() {
  image_ip=$(doctl compute droplet list --format "Name,PublicIPv4" | awk '/the-hunting/ {print $2}' | head -n1)
      #  ssh -o StrictHostKeyChecking=no -t root@"$image_ip" 'tmux attach -t hunting-0 -d'
      #tmux_session=$(echo "${response/:/}" | awk '/hunting/ {print $1}' | head -n1)
  ssh -o StrictHostKeyChecking=no -t root@"$image_ip" 'tmux attach -t hunting-0 -d'
}
# S3fs-fuse
function upload_s3_recon() {
  if [[ -z "$S3_BUCKET" ]]; then
    true
  else
    aws s3 cp --recursive ./targets/"$target_dir"/"$foldername" s3://"$S3_BUCKET"/targets/"$target_dir"/"$foldername" --profile the_hunting
    aws s3 cp ./s3-booty/"$target_dir"-newline.txt s3://"$S3_BUCKET"/s3-booty/newline/"$target_dir"-newline.txt --profile the_hunting
  fi
}
function upload_s3_scan() {
  if [[ -z "$S3_BUCKET" ]]; then
    true
  else
    aws s3 cp --recursive ./s3-booty/ s3://"$S3_BUCKET"/s3-booty/ --profile the_hunting
  fi
}
# children
function subdomain_enum() {
  echo "${yellow}Running Amass enum...${reset}"
  #Amass https://github.com/OWASP/Amass
  run_amass
  #run_json_amass
  #run_subfinder_json
  #parse_json
  echo "${green}Amass enum finished.${reset}"
  #Gobuster trying to make them run at same time
  #run_gobuster_vhost
  #run_gobuster_dns
}
function zap_whole() {
  open_program
  start_zap
  zap_spider
  stop_zap
  notify_spider_finished
  duration=$SECONDS
  echo "Completed in : $((duration / 60)) minutes and $((duration % 60)) seconds."
  stty sane
  tput sgr0
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
  #zap_whole
}
function port_scan() {
  run_nmap
}
# main func's
function recon() {
  subdomain_enum
  double_check_excluded
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
function print_line() {
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  echo " "
}
function credits() {
  base64 -d <<<"Q3JlZGl0czogVGhhbmtzIHRvIGh0dHBzOi8vZ2l0aHViLmNvbS9PSiBodHRwczovL2dpdGh1Yi5jb20vT1dBU1AgaHR0cHM6Ly9naXRodWIuY29tL2hhY2NlcgpodHRwczovL2dpdGh1Yi5jb20vdG9tbm9tbm9tIGh0dHBzOi8vZ2l0aHViLmNvbS9taWNoZW5yaWtzZW4gJiBUaGUgRGFyayBSYXZlciBmb3IgdGhlaXIKd29yayBvbiB0aGUgcHJvZ3JhbXMgdGhhdCB3ZW50IGludG8gdGhlIG1ha2luZyBvZiB0aGVfaHVudGluZy5zaC4="
  echo " "
}
function licensing_info() {
  base64 -d <<<"dGhlX2h1bnRpbmcgQ29weXJpZ2h0IChDKSAyMDIwICBAaW5jcmVkaW5jb21wClRoaXMgcHJvZ3JhbSBjb21lcyB3aXRoIEFCU09MVVRFTFkgTk8gV0FSUkFOVFk7IGZvciBkZXRhaWxzIGNhbGwgYC4vdGhlX2h1bnRpbmcuc2ggLWxpY2Vuc2UnLgpUaGlzIGlzIGZyZWUgc29mdHdhcmUsIGFuZCB5b3UgYXJlIHdlbGNvbWUgdG8gcmVkaXN0cmlidXRlIGl0Lgp1bmRlciBjZXJ0YWluIGNvbmRpdGlvbnM7IHR5cGUgYC4vdGhlX2h1bnRpbmcuc2ggLWxpY2Vuc2UnIGZvciBkZXRhaWxzLg=="
  echo " "
}
function print_line() {
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  echo " "
}
function open_program() {
  echo " "
  echo " "
  logo
  echo " "
  credits
  licensing_info
  print_line
}
# main
function recon_option() {
  target_dir=${target//./-}
  clear
  open_program
  if [ -d "./targets/"$target_dir"" ]; then
    echo "$target is a known target."
  else
    mkdir ./targets/"$target_dir"/
  fi
  if [ -z "$slack_url" ]; then
    echo "${red}Notifications not set up. Add your slack url to ./slack_url.txt${reset}"
  fi

  mkdir ./targets/"$target_dir"/"$foldername"
  mkdir ./targets/"$target_dir"/"$foldername"/aqua/
  mkdir ./targets/"$target_dir"/"$foldername"/aqua/aqua_out/
  mkdir ./targets/"$target_dir"/"$foldername"/aqua/aqua_out/parsedjson/
  mkdir ./targets/"$target_dir"/"$foldername"/subdomain_enum/
  mkdir ./targets/"$target_dir"/"$foldername"/subdomain_enum/amass/
  mkdir ./targets/"$target_dir"/"$foldername"/screenshots/
  mkdir ./targets/"$target_dir"/"$foldername"/scanning/
  mkdir ./targets/"$target_dir"/"$foldername"/scanning/nuclei/
  touch ./targets/"$target_dir"/"$foldername"/responsive-domains-80-443.txt
  touch ./targets/"$target_dir"/"$foldername"/subdomain-takeover-results.json
  touch ./targets/"$target_dir"/"$foldername"/alldomains.txt
  touch ./targets/"$target_dir"/"$foldername"/temp-clean.txt
  touch ./targets/"$target_dir"/"$foldername"/subdomains-jq.txt
  touch ./targets/"$target_dir"/"$foldername"/"$target_dir"-ips.txt

  excludedomains
  recon "$target"
  validation
  notify_finished
  double_check_excluded
  upload_s3_recon
  echo "${green}Scan for "$target" finished successfully${reset}"
  duration=$SECONDS
  echo "Completed in : $((duration / 60)) minutes and $((duration % 60)) seconds."
  stty sane
  tput sgr0
}
function scan_option() {
  clear
  open_program
  set_header
  if [ -n "$all_subdomain_scan_target_file" ]; then
    all_subdomain_scanning "$all_subdomain_scan_target_file"
  fi
  if [ -n "$subdomain_scan_target_file" ]; then
    subdomain_scanning "$subdomain_scan_target_file"
  fi
  upload_s3_scan
  notify_subdomain_scan
  send_file
  duration=$SECONDS
  echo "Completed in : $((duration / 60)) minutes and $((duration % 60)) seconds."
  stty sane
  tput sgr0
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
    --spider)
      zap_spider_target_file="$2"
      zap_whole
      shift
      shift
      ;;
    --install-pr)
      ./files/conf/install.sh --pre_reqs
      echo "Pre-requirements installed"
      exit
      ;;
    --install-all)
      ./files/conf/install.sh --install
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
    --tmux)
      tmux_image
      exit
      ;;
    --rmux)
      reconnect_tmux
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
    --help)
      usage
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
main() {
  # parse CLI arguments
  parse_args $@
  # exit if certain variables are not set
  if [ -z "$target" ] && [ -z "$subdomain_scan_target_file" ] && [ -z "$all_subdomain_scan_target_file" ] && [ -z "$zap_spider_target_file" ]; then
    usage
    exit 1
  fi
  if [ -n "$target" ]; then
    recon_option
  else
  #if [ -n "$subdomain_scan_target_file" ] || [ -n "$all_subdomain_scan_target_file" ]; then
    scan_option
  fi
}
todate=$(date +"%Y-%m-%d")
totime=$(date +"%I:%M")
path=$(pwd)
foldername=$todate"-"$totime
main $@
