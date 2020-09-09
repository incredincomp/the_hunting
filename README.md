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

If you are using axiom to set up boxes and youve done the proceeding command on said box.. you should be free and clear to use it. The script with install chromium each time it is ran in a new box because its not automatically installed in an axiom box.. you could add the snap command to your `.axiom/images/axiom.json` file but I just leave my script to do it on its own, only takes a second and you only have to do it once on each new box you `axiom-init`. 
*How I make it work for me...*

I start by using the -d option, then I take the resulting responsive-domains-80-443.txt file, (working on scripting this into -d with -e usage) then I open the file inside notepad++ and open find, search for out of scope domains, remove all mentions that match your scope, (working on this also for -d) then inside notepad++ go to find and replace - then in `find what` write `\n` and `replace with` write `,` then change search mode to extended and click find and replace all. **Note** Check the last line because if you have an extra new line that will be replaced by a stray `,`

You should be able to select all and copy and paste this file into your -s call now uninhibited. I personally am using ![eugeny/Terminus](https://github.com/eugeny/terminus) as my terminal so I have no issues with pasting URL lists of up to at least 880 hosts comprised of 28,000 different characters in a single command and having everything work out how it was designed.. screw any and all system resources honestly, they are machines.. break em then build em. Peace! ~@incredincomp


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

_Anything crossed out currently is implemented to a point, but turned off in the production version. Manually uncomment them in the script if you want to use them_

## Recon

### Subdomains

#### Subdomain Enum
~~gobuster - vhost & dns
https://github.com/OJ/gobuster~~

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

~~Gobuster - dir
https://github.com/OJ/gobuster~~

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
