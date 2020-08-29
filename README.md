# the_hunting
a *cheap* vuln finding robot

# Requirements

* Axiom https://github.com/pry0cc/axiom
* DigitalOcean Account
* Some API keys if you want good results for subdomain enum

# Commands
## Axiom
Start your axiom droplet

`axiom-init`

Connect to your axiom droplet

`axiom-ssh <instance> --tmux`

## Set up `the_hunting.sh`
`git pull https://github.com/incredincomp/the_hunting`

`cd ~/the_hunting`

`chmod +x install.sh the_hunting.sh`

need sudo for program installs with apt

`sudo ./install.sh`

# Methodology

## Recon

### Subdomains

#### Subdomain Enum
Subfinder
https://github.com/projectdiscovery/subfinder

Amass
https://github.com/OWASP/Amass

#### Subdomain TakeOver
Subjack
https://github.com/haccer/subjack

### Target Validation

#### Webserver Status Checks
Httprobe
https://github.com/tomnomnom/httprobe

#### Webpage Validation
aquatone
https://github.com/michenriksen/aquatone

## Scanning

### Fuzzing
#### Directory and file Fuzzing
Dirb
https://tools.kali.org/web-applications/dirb

Gobuster
https://github.com/OJ/gobuster

### Port Scanning
#### nmap

##### usage

##### nse scripts

### Webpage and Server Scanning

#### nuclei
##### Templates
##### usage
