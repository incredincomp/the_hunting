# the_hunting
a *cheap* vuln finding robot. Currently in heavy Dev. So please, be careful with it.. Its a violent script if I've ever written one. Nothing is rate limited so you'll probably get IP blocked over it, specifically during gobuster dir if youre not already banned before getting there.
Cheers!

< Huge shoutout to my dude ![@1efty](https://twitter.com/ONEefty) for his help bringing this script into the 21st century! && ![@1efty](https://github.com/1efty)'s github  />

Already changing the world around us to fit our needs :muscle:

[proof](https://github.com/projectdiscovery/nuclei/pull/330)

:heart: ~[@incredincomp](https://twitter.com/incredincomp)

# Requirements

* a healthy dose of tenacity
* DigitalOcean Account
* doctl installed and configured
* Some API keys if you want good results for subdomain enum
* Works on Ubuntu 20.04 + ask @1efty
* if you want to backup your box super easy without scp, configure aws like below

# Warning
Slack integration is included.. you need to add some data to aptly named files and you should be off to the races. Mind you, if you set up file upload by filling in the proper data in `./bot_user_oauth_at.txt` and `./slack_channel.txt`, you also need to have the a bot setup with the proper permissions to post files to whatever channel, then invite the bot to that channel.

Your data is in slacks hands then though, so if you are working within specific privacy and private program scopes, you may need to adjust course accordingly and do some research before you start dumping possibly important data on your targets into slacks servers and therefore the world. Be smart about it.

# Commands
## Set up `the_hunting.sh` on

install the hunting
```bash
git clone https://github.com/incredincomp/the_hunting.git && cd the_hunting/
```

install pre-reqs make and packer
```bash
chmod +x reqs.sh
./reqs.sh
```

export your digital ocean api key to env
```bash
export DIGITALOCEAN_ACCESS_TOKEN=1234546789abcdefghijkl
```

export your digital ocean ssh key fingerprint to env
```bash
export hunting_fingerprint=11:22:33:44:55:66:77:88:99:AA
```

## Building box
From inside /the_hunting.. run
```bash
make build
```
Should complete after about 10 minutes.

### *THE INSTALL.SH SCRIPT IS SOMEWHAT TESTED, NOW BETTER FORMATTED, AND STILL MAYBE DANGEROUS.. GOOD LUCK*
need sudo for program installs with packaging program

```bash
sudo ./install.sh --install
```

## Usage

Pass this command your sshkey fingerprint from Digital that you would like to use for this box.

```bash
./the_hunting.sh --create $hunting_fingerprint
```

connect to your box

```bash
./the_hunting.sh --connect
```

tmux to your box

```bash
./the_hunting.sh --tmux
```

delete your box

```bash
./the_hunting.sh --remove
```

Recon a root domain name for responsive subdomains

```bash
./the_hunting.sh --target hackerone.com
```

Exclude out of scope domains from your recon results before doing recon (leaving you with a clean scope subdomain list)

```bash
./the_hunting.sh --target hackerone.com --exclude support.hackerone.com,go.hacker.one,www.hackeronestatus.com,info.hacker.one,ma.hacker.one
```

Scan a file list of subdomains seperated by new line

```bash
./the_hunting.sh --file subdomains.txt
```

This will run all nuclei templates on your list of targets inside of `subdomains.txt`

```bash
./the_hunting.sh --file-all subdomains.txt
```

Work in progress to start a scan and then auto kill the box
```bash
#connect to your box and set up the kill for after
./the_hunting.sh --connect && ./the_hunting.sh --remove y
#once connected, run a scan such as this to both do recon, then scan the found domains, then exit the box
./the_hunting.sh --target hackerone.com --exclude support.hackerone.com,go.hacker.one,www.hackeronestatus.com,info.hacker.one,ma.hacker.one && ./the_hunting.sh --file ./s3-booty/hackerone-com-newline.txt && exit
```

## Configuration
### Config Files
All your user config files are to be stored inside of `./backup-files/`. I have placed default configs for subfinder and amass in here for you, as well as the other files needed for a fully configured instance. 
*The one really important one right now is the `./backup-files/subfinder.yaml` one, add some keys/delete all the stuff you dont need.*

### Configure AWS for backups.
You are going to need to run `sudo ./reqs.sh` and configure AWS cli through that prompt or have it done previously.

# To-Do/Upcoming
1. ~~switching to aws, probably cheaper and easier to manage. Able to store data and probably just send some encrypted emails.. *maybe need a domain for that though* ![#34](https://github.com/incredincomp/the_hunting/issues/34)~~
2. ~~fixing directory structure/house cleaning ![#30](https://github.com/incredincomp/the_hunting/issues/30)~~


# Methodology

![](https://github.com/incredincomp/usage-videos/blob/master/the_hunting1.PNG)

_Anything crossed out currently is implemented to a point, but turned off in the production version. Manually uncomment them in the script if you want to use them_

## Recon

### Subdomains

#### Subdomain Enum
~~gobuster - vhost & dns
https://github.com/OJ/gobuster~~

~~Amass~~
~~https://github.com/OWASP/Amass~~

Subfinder
https://github.com/projectdiscovery/subfinder

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
~~#### Directory and file Fuzzing~~
~~to-do: Dirb~~
~~https://tools.kali.org/web-applications/dirb~~

~~Gobuster - dir
https://github.com/OJ/gobuster~~

~~### Port Scanning~~
~~#### To-do: nmap~~

~~##### nse scripts~~

~~https://nmap.org/book/nse.html~~

### Webpage and Server Scanning

#### nuclei

##### Templates

Community templates - https://github.com/projectdiscovery/nuclei-templates

~~To-Do: User made templates - https://nuclei.projectdiscovery.io/templating-guide/~~

#### Owasp ZAProxy

https://github.com/zaproxy/zaproxy
