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
#  REQUIREMENTS:
#
#          BUGS:
#         NOTES: v0.0.1
#        AUTHOR: @incredincomp
#  ORGANIZATION:
#       CREATED: 08/27/2020 16:55:54
#      REVISION: 08/29/2020 11:06:00
#     LICENSING:
#===============================================================================
clear
set -o nounset                              # Treat unset variables as an error
set -e
set -xv                                    # Uncomment to print script in console for debug

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

# borrowed some stuff and general idea of automated platform from lazyrecon https://github.com/nahamsec/lazyrecon
auquatoneThreads=5
subdomainThreads=10
chromiumPath=/snap/bin/chromium

logo(){
echo "${red}the_hunting.sh${reset}"
}

target=""
subreport=""
usage() { logo; echo -e "Usage: ./the_hunting.sh -d <target domain> [-e] [excluded.domain.com,other.domain.com]\nOptions:\n  -e\t-\tspecify excluded subdomains\n " 1>&2; exit 1; }

while getopts ":d:e:r" o; do
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
        r)
            subreport+=("$OPTARG")
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
  amass enum -norecursive --passive -dir ./targets/"$target"/"$foldername"/subdomain_enum/amass/ -json ./targets/"$target"/"$foldername"/subdomain_enum/amass_"$todate".json -d "$target"
  rm -rf ./targets/"$target"/"$foldername"/subdomain_enum/amass/amass.log
  cat ./targets/"$target"/"$foldername"/subdomain_enum/amass/amass.txt >> ./targets/"$target"/"$foldername"/alldomains.txt
}

run_gobuster_vhost(){
  true
}

run_gobuster_dns(){
  true
}

run_subjack(){
  true
}

run_subjack(){
  true
}

run_nmap(){
  true
}

run_aqua(){
  echo "Starting aquatone scan..."
#    cat ./targets/"$target"/"$foldername"/urilist.txt | aquatone -chrome-path $chromiumPath -out ./$target/aqua/aqua_out -threads $auquatoneThreads -silent
  true
}

run_gobuster_dir(){
  true
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

# children
subdomain_enum(){
#Amass https://github.com/OWASP/Amass
  run_amass
#Gobuster
  run_gobuster_vhost
  run_gobuster_dns
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
  if [ -z "${target}" ]; then
    domain=${subreport[1]}
    foldername=${subreport[2]}
    subd=${subreport[3]}
    report $target $subdomain $foldername $subd; exit 1;
  fi
  clear
  logo
  cd ./targets && if [ -d "./$target" ]
  then
    echo "This is a known target."
  else
    mkdir ./$target
  fi && cd ..

  mkdir ./targets/$target/"$foldername"
  mkdir ./targets/$target/"$foldername"/aqua_out
  mkdir ./targets/$target/"$foldername"/aqua_out/parsedjson
  mkdir ./targets/$target/"$foldername"/reports/
  mkdir ./targets/$target/"$foldername"/subdomain_enum/
  mkdir ./targets/$target/"$foldername"/subdomain_enum/amass
  mkdir ./targets/$target/"$foldername"/screenshots/
  touch ./targets/$target/"$foldername"/crtsh.txt
  touch ./targets/$target/"$foldername"/mass.txt
  touch ./targets/$target/"$foldername"/cnames.txt
  touch ./targets/$target/"$foldername"/pos.txt
  touch ./targets/$target/"$foldername"/alldomains.txt
  touch ./targets/$target/"$foldername"/temp.txt
  touch ./targets/$target/"$foldername"/tmp.txt
  touch ./targets/$target/"$foldername"/domaintemp.txt
  touch ./targets/$target/"$foldername"/ipaddress.txt
  touch ./targets/$target/"$foldername"/cleantemp.txt
  touch ./targets/$target/"$foldername"/master_report.html

  recon "$target"
  scanning
  echo "${green}Scan for $target finished successfully${reset}"
  duration=$SECONDS
  echo "Completed in : $((duration / 60)) minutes and $((duration % 60)) seconds."
  stty sane
  tput sgr0
}

todate=$(date +"%Y-%m-%d")
path=$(pwd)
foldername="$todate"
main "$target"
