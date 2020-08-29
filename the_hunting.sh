#!/bin/bash -
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
#         NOTES: v0.0.0
#        AUTHOR: @incredincomp
#  ORGANIZATION:
#       CREATED: 08/27/2020 16:55:54
#      REVISION: 00/00/2020 00:00:00
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
auquatoneThreads=5
subdomainThreads=10
dirsearchThreads=50
dirsearchWordlist=~/tools/dirsearch/db/dicc.txt
chromiumPath=/snap/bin/chromium
target=

usage() { echo -e "Usage: ./the_hunting.sh -d <target domain> [-e] [excluded.domain.com,other.domain.com]\nOptions:\n  -e\t-\tspecify excluded subdomains\n " 1>&2; exit 1; }

while getopts ":d:e:r:" o; do
    case "${o}" in
        d)
            target=${OPTARG}
            ;;
        e)
            set -f
	    IFS=","
	    excluded+=("$OPTARG")
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

subdomain_enum(){
true
}

sub_takeover(){
true
}

run_nmap(){
true
}

run_aqua(){
    echo "Starting aquatone scan..."
    cat ./"$target"/urilist.txt | aquatone -chrome-path $chromiumPath -out ./$target/aqua/aqua_out -threads $auquatoneThreads -silent
}

recon(){
    subdomain_enum
    sub_takeover
    run_nmap
    run_aqua
    
}

scanning(){
#nuclei
true
}

logo(){
echo "${red}the_hunting.sh${reset}"
}

main(){
if [ -z "${target}" ]; then
target=${subreport[1]}
foldername=${subreport[2]}
subd=${subreport[3]}
fi
  clear
  logo
  if [ -d "./$target" ]
  then
    echo "This is a known target."
  else
    mkdir ./$target
  fi

  mkdir ./"$target"/"$foldername"
  mkdir ./"$target"/"$foldername"/aqua_out
  mkdir ./"$target"/"$foldername"/aqua_out/parsedjson
  mkdir ./"$target"/"$foldername"/reports/
  mkdir ./"$target"/"$foldername"/wayback-data/
  mkdir ./"$target"/"$foldername"/screenshots/
  touch ./"$target"/"$foldername"/crtsh.txt
  touch ./"$target"/"$foldername"/mass.txt
  touch ./"$target"/"$foldername"/cnames.txt
  touch ./"$target"/"$foldername"/pos.txt
  touch ./"$target"/"$foldername"/alldomains.txt
  touch ./"$target"/"$foldername"/temp.txt
  touch ./"$target"/"$foldername"/tmp.txt
  touch ./"$target"/"$foldername"/domaintemp.txt
  touch ./"$target"/"$foldername"/ipaddress.txt
  touch ./"$target"/"$foldername"/cleantemp.txt
  touch ./"$target"/"$foldername"/master_report.html

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
foldername=recon-$todate
main "$target"
