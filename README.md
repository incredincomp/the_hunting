# the_hunting
a *cheap* vuln finding robot. Currently in heavy Dev. So please, be careful with it.. Its a violent script if I've ever written one. Nothing is rate limited so you'll probably get IP blocked over it, specifically during gobuster dir if youre not already banned before getting there.
Cheers!

< Huge shoutout to my dude ![@1efty](https://twitter.com/ONEefty) for his help bringing this script into the 21st century! && ![@1efty](https://github.com/1efty)'s github  />

Already changing the world around us to fit our needs :muscle:

[proof](https://github.com/projectdiscovery/nuclei/pull/330)

:heart: ~[@incredincomp](https://twitter.com/incredincomp)

# Requirements

* a healthy dose of tenacity
* DigitalOcean Account - [use this link to get $100 in free credit.. plus get me $25! :)](https://m.do.co/c/84db7470d259)
* doctl installed and configured
* Some API keys if you want good results for subdomain enumeration
* Works on Ubuntu 20.04 + ask @1efty
* if you want to backup your box super easy without scp, configure aws (need your iam account Access key ID and the Secret access key)

# Warning
Slack integration is included.. you need to add some data to aptly named files and you should be off to the races. Mind you, if you set up file upload by filling in the proper data in `./bot_user_oauth_at.txt` and `./slack_channel.txt`, you also need to have the a bot setup with the proper permissions to post files to whatever channel, then invite the bot to that channel.

Your data is in slacks hands then though, so if you are working within specific privacy and private program scopes, you may need to adjust course accordingly and do some research before you start dumping possibly important data on your targets into slacks servers and therefore the world. Be smart about it.

# Commands
## Set up `the_hunting.sh` on

download the hunting
```bash
git clone https://github.com/incredincomp/the_hunting.git && cd the_hunting/
```

install pre-reqs make and packer and congifure aws for secure cold storage
```bash
sudo ./reqs.sh
```

export your digital ocean api key to env
```bash
export DIGITALOCEAN_ACCESS_TOKEN="1234546789abcdefghijkl"
```

export your digital ocean ssh key fingerprint to env
```bash
export hunting_fingerprint="11:22:33:44:55:66:77:88:99:AA"
```

## Building box snapshot for use with `--create`
From inside /the_hunting.. run
```bash
make build
```
Should complete after <=> 10 minutes.

## Usage

### To build a remote box on DO

Use this command to generate a new droplet based off your make build snapshot

```bash
./the_hunting.sh --create
```

connect to your box

```bash
./the_hunting.sh --connect
```

start first tmux session on your box and connect, to leave the_hunting running when you leave.. press `ctrl + b` then `d`

```bash
./the_hunting.sh --tmux
```

reconnect to your last tmux session
```bash
./the_hunting.sh --reconnect-tmux
```

delete your box

```bash
./the_hunting.sh --remove
```

### To install and run locally (not needed with a droplet)

install script prereqs needed for running, from inside `./the_hunting/` call

```bash
./the_hunting.sh --install-all
```

### Script's usage anywhere
Recon a root domain name for responsive subdomains

```bash
./the_hunting.sh --target hackerone.com
```

Exclude out of scope domains from your recon results before doing recon (leaving you with a clean scope subdomain list in responsive-domains...txt)

```bash
./the_hunting.sh --target hackerone.com --exclude support.hackerone.com,go.hacker.one,www.hackeronestatus.com,info.hacker.one,ma.hacker.one
```

Scan a file list of subdomains separated by new line

```bash
./the_hunting.sh --file subdomains.txt
```

This will run all nuclei templates on your list of targets inside of `subdomains.txt`

```bash
./the_hunting.sh --file-all subdomains.txt
```

Spider a list of urls with owaspzap

```bash
./the_hunting.sh --spider important-subdomains.txt
```

## Configuration
### Config Files
![](https://github.com/incredincomp/usage-videos/blob/master/important_files.jpg)

All your user config files are to be stored inside of `./backup-files/`. I have placed default configs for subfinder and amass in here for you, as well as the other files needed for a fully configured instance. The tokens are pretty aptly named, but these are all optional and are meant to enhance the script to some degree.
`custom-header.txt` can be used to set your header for scans.. otherwise you can just run the scan option and it will ask you everytime now as it starts

### Configure AWS for backups.
You are going to need to run `sudo ./reqs.sh` and configure AWS cli through that prompt or have it done previously.

# To-Do/Upcoming
1. ~~switching to aws, probably cheaper and easier to manage. Able to store data and probably just send some encrypted emails.. *maybe need a domain for that though* ![#34](https://github.com/incredincomp/the_hunting/issues/34)~~
2. ~~fixing directory structure/house cleaning ![#30](https://github.com/incredincomp/the_hunting/issues/30)~~


# Methodology

![](https://github.com/incredincomp/usage-videos/blob/master/the_hunting1.PNG)

_Anything crossed out currently is implemented to a point, but turned off in the production version. Manually uncomment them in the script if you want to use them, do it on lines 377-414_

## Recon

### Subdomains

#### Subdomain Enum
~~gobuster - vhost & dns
https://github.com/OJ/gobuster~~

Amass
https://github.com/OWASP/Amass

~~Subfinder
https://github.com/projectdiscovery/subfinder~~

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

~~https://github.com/zaproxy/zaproxy~~
