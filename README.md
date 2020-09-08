# the_hunting
a *cheap* vuln finding robot. Currently in Dev. Please be careful with it. Its a violent script if I've ever written one. Only does Recon branch fully right now, still pretty useful probably. Nothing is rate limited so youll probably get IP blocked over it, specifically during gobuster dir if youre not already banned before getting there.
Cheers!

< Huge shoutout to my dude @1efty for his help bringing this script into the 21st century!

https://github.com/1efty https://twitter.com/ONEefty />
# Requirements

* Axiom https://github.com/pry0cc/axiom
* DigitalOcean Account
* Some API keys if you want good results for subdomain enum

# Warning
Slack integration is included.. you need to add some data to aptly named files and you should be off to the races. Mind you, if you set up file upload by filling in the proper data in `./bot_user_oauth_at.txt` and `./slack_channel.txt`, you also need to have the a bot setup with the proper permissions to post files to whatever channel, then invite the bot to that channel. 

Your data is in slacks hands then though, so if you are working within specific privacy and private program scopes, you may need to adjust course accordingly and do some research before you start dumping possibly important data on your targets into slacks servers and therefore the world. Be smart about it.

# Commands
## Axiom
Start your axiom droplet

`axiom-init`

Connect to your axiom droplet

`axiom-ssh <instance> --tmux`

## Set up `the_hunting.sh`

```bash
git clone --recurse-submodules https://github.com/incredincomp/the_hunting.git
cd the_hunting/
```

### need to run install.sh on fresh ubuntu 20.04 to install pre-req tools that come with axiom *THIS IS UNTESTED AND DANGEROUS, GOOD LUCK
`chmod +x install.sh the_hunting.sh`

### *THE INSTALL.SH SCRIPT IS UNTESTED, UNFORMATTED, AND DANGEROUS.. GOOD LUCK*
need sudo for program installs with apt

`sudo ./install.sh -i`

## Usage
Recon a root domain name for responsive subdomains

`./the_hunting.sh -d <target domain>`

Exclude out of scope domains from your recon results before scanning

`./the_hunting.sh -d <target domain> -e excluded.domain.com,other.domain.com`

Scan a CSV list of subdomains from the cli

`./the_hunting.sh -s sub.domain.com,sue.domain.com,paul.domain.com`


# Methodology

![](https://github.com/incredincomp/usage-videos/blob/master/the_hunting1.PNG)

## Recon

### Subdomains

#### Subdomain Enum
gobuster - vhost & dns
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
to-do: Dirb
https://tools.kali.org/web-applications/dirb

Gobuster - dir
https://github.com/OJ/gobuster

### Port Scanning
#### To-do: nmap

##### usage

##### nse scripts

https://nmap.org/book/nse.html

### Webpage and Server Scanning

#### nuclei

##### Templates

Community templates - https://github.com/projectdiscovery/nuclei-templates

To-Do: User made templates - https://nuclei.projectdiscovery.io/templating-guide/

##### usage
