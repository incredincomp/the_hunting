# the_hunting
a *cheap* vuln finding robot

Currently in Dev. Please be careful with it. Its a violent script if I've ever written one. Only does Recon branch fully right now, still pretty useful probably.
Cheers!

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

### need to run install.sh on fresh ubuntu 20.04 to install prereq tools that come with axiom *THIS IS UNTESTED AND DANGEROUS, GOOD LUCK
`chmod +x install.sh the_hunting.sh`

### *THE INSTALL.SH SCRIPT IS UNTESTED, UNFORMATTED, AND DANGEROUS.. GOOD LUCK*
need sudo for program installs with apt

`sudo ./install.sh`

## Usage
`./the_hunting.sh -d <target domain>`

# Methodology

![](https://github.com/incredincomp/usage-videos/blob/master/the_hunting1.PNG)

## Recon

### Subdomains

#### Subdomain Enum
gobuster
https://github.com/OJ/gobuster

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

https://nmap.org/book/nse.html

### Webpage and Server Scanning

#### nuclei

##### Templates

https://github.com/projectdiscovery/nuclei-templates

https://nuclei.projectdiscovery.io/templating-guide/

##### usage
